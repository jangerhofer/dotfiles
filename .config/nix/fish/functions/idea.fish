function idea --description="Launch IntelliJ IDEA"
    /Applications/IntelliJ\ IDEA.app/Contents/MacOS/idea $argv >/dev/null 2>&1 &
    disown
end
