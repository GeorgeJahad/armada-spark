#!/bin/bash

# Configuration
APP_LABEL="${1:-xxx}"  # First argument or default to 'xxx'
LOG_DIR="${2:-./pod_logs/$APP_LABEL}"  # Second argument or default to './pod_logs/<label>'
NAMESPACE="${3:-default}"  # Third argument or default to 'default'

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Track background processes
PIDS_FILE="$LOG_DIR/.log_pids"
touch "$PIDS_FILE"

echo "Starting log collection for spark-app-selector=$APP_LABEL in namespace $NAMESPACE"
echo "Logs will be stored in: $LOG_DIR"
echo "Press Ctrl+C to stop"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo "Stopping all log collection processes..."
    while read -r pid; do
        if ps -p "$pid" > /dev/null 2>&1; then
            kill "$pid" 2>/dev/null
        fi
    done < "$PIDS_FILE"
    rm -f "$PIDS_FILE"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Function to wait for a pod to reach Running state, then follow its logs
follow_pod_logs() {
    local pod_name=$1
    local log_file="$LOG_DIR/${pod_name}.log"

    echo "Waiting for pod $pod_name to be Running..."

    # Wait until the pod is in Running (or Succeeded/Failed, meaning it already ran)
    while true; do
        local phase
        phase=$(kubectl --kubeconfig=/home/gbj/incoming/tigKubeConfig get pod "$pod_name" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null)
        case "$phase" in
            Running|Succeeded|Failed)
                break
                ;;
            "")
                # Pod disappeared
                echo "✗ Pod $pod_name no longer exists, skipping"
                return
                ;;
        esac
        sleep 2
    done

    echo "Starting log collection for pod: $pod_name -> $log_file"

    # Follow the logs in the background
    kubectl --kubeconfig=/home/gbj/incoming/tigKubeConfig logs -f "$pod_name" -n "$NAMESPACE" > "$log_file" 2>&1 &
    local pid=$!

    # Track the PID
    echo "$pid" >> "$PIDS_FILE"

    # Monitor this specific process and remove from tracking when it exits
    (
        wait "$pid"
        # Remove this PID from the file
        sed -i "/^${pid}$/d" "$PIDS_FILE" 2>/dev/null
        echo "✓ Pod $pod_name finished (log saved in $log_file)"
    ) &
}

# Track which pods we're already following
declare -A FOLLOWING_PODS

# Main loop
while true; do
    # Get all pods with the specified label
    PODS=$(kubectl  --kubeconfig=/home/gbj/incoming/tigKubeConfig get pods -n "$NAMESPACE" -l "spark-app-selector=$APP_LABEL" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)

#    echo gbj $PODS

    # Start following logs for any new pods
    for pod in $PODS; do
        if [[ -z "${FOLLOWING_PODS[$pod]}" ]]; then
            follow_pod_logs "$pod" &
            FOLLOWING_PODS[$pod]=1
        fi
    done

    # Wait before checking for new pods
    sleep 5
done
