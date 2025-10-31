#!/bin/bash
#
# Slack Notification Script for Claude Code Hooks
# =================================================
# This script extracts user prompts and assistant responses from conversation
# history, generates a summary using Gemini AI, and sends it to Slack.
#
# Usage:
#   echo '{"transcript_path": "/path/to/file.jsonl", "title": "Task"}' | ./slack-notify.sh [notification|stop]
#
# Environment Variables:
#   ECCUBE_DEV_AGENTS_SLACK_WEBHOOK_URL - Slack webhook URL (required)
#   DEBUG - Set to 1 to enable debug output
#

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "$0")"
readonly MESSAGE_LIMIT=10  # Number of recent messages to extract
readonly DEBUG="${DEBUG:-0}"

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------

# Print error message to stderr
error() {
    echo "ERROR: $*" >&2
}

# Print debug message if DEBUG is enabled
debug() {
    if [[ "$DEBUG" == "1" ]]; then
        echo "DEBUG: $*" >&2
    fi
}

# Print info message to stderr
info() {
    echo "INFO: $*" >&2
}

# Exit with error message
die() {
    error "$@"
    exit 1
}

# -----------------------------------------------------------------------------
# Input Processing
# -----------------------------------------------------------------------------

# Read and parse JSON input from stdin
read_input() {
    local input
    input=$(cat)
    debug "Received input: ${input:0:100}..."
    echo "$input"
}

# Extract transcript path from input JSON
extract_transcript_path() {
    local input="$1"
    local path

    path=$(echo "$input" | jq -r '.transcript_path')

    if [[ "$path" == "null" || -z "$path" ]]; then
        die "transcript_path not found in input JSON"
    fi

    if [[ ! -f "$path" ]]; then
        die "Transcript file not found: $path"
    fi

    debug "Transcript path: $path"
    echo "$path"
}

# Extract title from input JSON
extract_title() {
    local input="$1"
    local title

    title=$(echo "$input" | jq -r '.title // "Untitled"')
    debug "Title: $title"
    echo "$title"
}

# Determine event type (notification or stop)
determine_event_type() {
    local event_type="${1:-notification}"

    if [[ "$event_type" != "notification" && "$event_type" != "stop" ]]; then
        error "Unknown event type: $event_type, defaulting to notification"
        event_type="notification"
    fi

    debug "Event type: $event_type"
    echo "$event_type"
}

# -----------------------------------------------------------------------------
# Message Extraction
# -----------------------------------------------------------------------------

# Extract recent messages from transcript file
extract_messages() {
    local transcript_path="$1"
    local messages

    messages=$(jq -s ".[-${MESSAGE_LIMIT}:]" "$transcript_path")
    debug "Extracted ${MESSAGE_LIMIT} recent messages"
    echo "$messages"
}

# Extract user prompts from messages
extract_user_prompts() {
    local messages="$1"
    local prompts

    prompts=$(echo "$messages" | jq -r '
        [.[] |
         select(.type == "user" and .message.content[0].text != null) |
         .message.content[0].text
        ] | join("\n---\n")
    ')

    debug "Extracted user prompts (length: ${#prompts})"
    echo "$prompts"
}

# Extract assistant responses from messages
extract_assistant_responses() {
    local messages="$1"
    local responses

    responses=$(echo "$messages" | jq -r '
        [.[] |
         select(.type == "assistant" and .message.content[0].text != null) |
         .message.content[0].text
        ] | join("\n---\n")
    ')

    debug "Extracted assistant responses (length: ${#responses})"
    echo "$responses"
}

# -----------------------------------------------------------------------------
# Summary Generation
# -----------------------------------------------------------------------------

# Build Gemini prompt based on event type
build_gemini_prompt() {
    local event_type="$1"
    local title="$2"
    local user_prompts="$3"
    local assistant_responses="$4"
    local prompt

    local context="タイトル: $title

【ユーザーの入力】
$user_prompts

【Claudeの応答】
$assistant_responses"

    if [[ "$event_type" == "stop" ]]; then
        prompt="タスク完了の通知です。以下の会話を要約してください：

$context

以下の形式で日本語で要約してください：

📝 *ユーザーの依頼:*
[ユーザーが入力したプロンプト/質問の要点を簡潔に]

🤖 *対応内容:*
[Claude Codeが実施した作業の概要]

✅ *結果:*
[完了したタスクの成果]

絵文字を使って読みやすくし、Slack の mrkdwn 形式を使用してください。"
    else
        prompt="タスク確認の通知です。以下の会話を要約してください：

$context

以下の形式で日本語で要約してください：

📝 *ユーザーの依頼:*
[ユーザーが入力したプロンプト/質問の要点を簡潔に]

🤖 *対応内容:*
[Claude Codeが実施した作業の概要]

絵文字を使って読みやすくし、Slack の mrkdwn 形式を使用してください。"
    fi

    debug "Built Gemini prompt (length: ${#prompt})"
    echo "$prompt"
}

# Generate summary using Gemini AI
generate_summary() {
    local prompt="$1"
    local summary

    info "Generating summary with Gemini AI..."

    if ! summary=$(echo "$prompt" | gemini -m gemini-2.5-flash 2>&1); then
        die "Failed to generate summary with Gemini: $summary"
    fi

    debug "Summary generated (length: ${#summary})"
    echo "$summary"
}

# -----------------------------------------------------------------------------
# Slack Integration
# -----------------------------------------------------------------------------

# Check if Slack webhook URL is configured
check_slack_webhook() {
    if [[ -z "${ECCUBE_DEV_AGENTS_SLACK_WEBHOOK_URL:-}" ]]; then
        error "ECCUBE_DEV_AGENTS_SLACK_WEBHOOK_URL is not set"
        info "Skipping Slack notification"
        return 1
    fi

    debug "Slack webhook URL is configured"
    return 0
}

# Build Slack message payload
build_slack_payload() {
    local summary="$1"
    local payload

    payload=$(jq -n --arg text "$summary" '{
        blocks: [
            {
                type: "section",
                text: {
                    type: "mrkdwn",
                    text: $text
                }
            }
        ]
    }')

    debug "Built Slack payload"
    echo "$payload"
}

# Send notification to Slack
send_to_slack() {
    local payload="$1"
    local response

    info "Sending notification to Slack..."

    if ! response=$(curl -s -w "\n%{http_code}" -X POST \
        -H 'Content-type: application/json' \
        -d "$payload" \
        "${ECCUBE_DEV_AGENTS_SLACK_WEBHOOK_URL}" 2>&1); then
        die "Failed to send to Slack: $response"
    fi

    local http_code
    http_code=$(echo "$response" | tail -n1)

    if [[ "$http_code" != "200" ]]; then
        die "Slack API returned error code: $http_code"
    fi

    info "Slack notification sent successfully"
}

# -----------------------------------------------------------------------------
# Main Function
# -----------------------------------------------------------------------------

main() {
    local event_type
    event_type=$(determine_event_type "${1:-}")

    # Read input from stdin
    local input
    input=$(read_input)

    # Extract parameters
    local transcript_path
    local title
    transcript_path=$(extract_transcript_path "$input")
    title=$(extract_title "$input")

    # Extract messages
    local messages
    local user_prompts
    local assistant_responses
    messages=$(extract_messages "$transcript_path")
    user_prompts=$(extract_user_prompts "$messages")
    assistant_responses=$(extract_assistant_responses "$messages")

    # Generate summary
    local gemini_prompt
    local summary
    gemini_prompt=$(build_gemini_prompt "$event_type" "$title" "$user_prompts" "$assistant_responses")
    summary=$(generate_summary "$gemini_prompt")

    # Send to Slack (if configured)
    if check_slack_webhook; then
        local payload
        payload=$(build_slack_payload "$summary")
        send_to_slack "$payload"
    else
        # Just print summary if Slack is not configured
        echo "=== Generated Summary ==="
        echo "$summary"
        echo "========================="
    fi
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

main "$@"
