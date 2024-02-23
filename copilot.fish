function json_escape_string
    echo $argv | python -c "import sys;import json;print(json.dumps(sys.stdin.read()))" | sed 's/^"\(.*\)\\\n"$/\1/g'
end

function history_context
    echo (history | head -n 25)
end

function openai_chat
    set model "gpt-4"
    set system_prompt (json_escape_string "You are a helpful assistant that is tasked with giving a completion for a user input command for the fish shell. \
For example: if the user types `ls`, you could respond with `ls -l`, if the user types `cd`, you could respond with `cd ..`. \
The examples are just to give you an idea of what to do. Use the best completion you can think of. \
Recent commands: $(history_context) \
Make sure to respond with the full command, including any arguments. If you don't have a good response, just respond with the user input.")
    set user_prompt (json_escape_string $argv)
    set data "{\"model\": \"$model\", \"messages\": [{\"role\": \"system\", \"content\": \"$system_prompt\"}, {\"role\": \"user\", \"content\": \"$user_prompt\"}]}"

    set reponse (curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d $data
    )
    set message (echo $reponse | jq -r '.choices[0].message.content')
    echo $message
end

function fishpilot
    set current_command (commandline)
    set response (openai_chat $current_command)
    commandline -r $response
end

bind \cn fishpilot
