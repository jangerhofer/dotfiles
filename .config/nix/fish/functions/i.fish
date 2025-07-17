function i --description="Launch IntelliJ IDEA with directory resolution"
    if test (count $argv) -eq 1
        # Use `z` to resolve the directory
        set dir (z -e $argv[1])
        if test -n "$dir"
            /Applications/IntelliJ\ IDEA.app/Contents/MacOS/idea "$dir" >/dev/null 2>&1 &
            disown
        else
            echo "No match found for '$argv[1]'"
        end
    else
        echo "Usage: i <directory>"
    end
end
