
fail_fast=$1
exit_code=$2
commit_filter=$3
commit_filter_separator=$4

IFS=$commit_filter_separator read -ra filters <<< "$commit_filter"

# Based on: https://github.com/marketplace/actions/skip-based-on-commit-message
last_commit_log=$(git log -1 --pretty=format:"%s %b")

readonly local is_merge_commit=$(echo "$last_commit_log" | egrep -c "Merge [a-zA-Z0-9]* into [a-zA-Z0-9]*")
if [[ "$is_merge_commit" -eq 1 ]]; then
  readonly local commit_id=$(echo "$last_commit_log" | sed 's/Merge //' | sed 's/ into [a-zA-Z0-9]*//')
  last_commit_log=$(git log -1 --pretty="%s %b" $commit_id)
fi
echo "Last commit log: $last_commit_log"

total_filter_count=0
for filter in "${filters[@]}"; do
	filter_count=$(echo "$last_commit_log" | fgrep -c "$filter")
	total_filter_count=$((filter_count+total_filter_count))
done
echo "Number of occurrences of '$commit_filter': $total_filter_count"

if [[ "$total_filter_count" -eq 0 ]]; then
  echo "The last commit log does not contains \"$commit_filter\", setting environment variables for next steps:"
  echo "CI_SKIP=false"
  echo "CI_SKIP_NOT=true"
  echo "CI_SKIP=false" >> $GITHUB_ENV
  echo "CI_SKIP_NOT=true" >> $GITHUB_ENV
  echo "And continue..."
else
  if [[ $fail_fast == 'true' ]]; then
    echo "The last commit log contains \"$commit_filter\", exiting"
    # It's impossible to finish workflow with success, so exiting using exit-code
    exit "$exit_code"
  else
    echo "The last commit log contains \"$commit_filter\", setting environment variables for next steps:"
    echo "CI_SKIP=true"
    echo "CI_SKIP_NOT=false"
    echo "CI_SKIP=true" >> $GITHUB_ENV
    echo "CI_SKIP_NOT=false" >> $GITHUB_ENV
    echo "And continue..."
  fi
fi
