#!/bin/bash
# author: Kilian Lindberg 2024
# co-author and inspiration: everyone & Lama
# license: MIT License

# Brief description of the script's purpose and functionality
# This script adds and manages aliases in the .bashrc file.

# Function to update .bashrc with new alias or environment variable

update_bashrc() {
    local entry="$1"
    local file="$HOME/.bashrc"
    echo "Updating .bashrc with entry: $entry"
    if ! grep -qF "$entry" "$file"; then
        echo "$entry" >> "$file"
        echo "Added $entry to $file"
    else
        echo "$entry already exists in $file"
    fi
}

# Function to add alias to .bashrc
add_alias_to_bashrc() {
    local alias_name="$1"
    local command="$2"
    local file="$HOME/.bashrc"

    # Validate alias name
    if ! [[ "$alias_name" =~ ^[a-zA-Z_] ]]; then
        echo "Invalid alias name: $alias_name"
        exit 1
    fi

    # Check if alias is already defined
    if type -t "$alias_name" > /dev/null 2>&1; then
        echo "Alias $alias_name is already defined."
        return
    fi

    # Check if alias is already present in .bashrc (either uncommented or commented out)
    if grep -qE "^alias\s+$alias_name=|^#.*alias\s+$alias_name=" "$file"; then
        if grep -qE "^#.*alias\s+$alias_name=" "$file"; then
            # If the alias is commented out, uncomment it and update the command
            sed -i "s/^#*alias $alias_name=.*/alias $alias_name='$command'/" "$file"
            echo "Updated alias $alias_name in $file"
        else
            existing_command=$(grep -E "^alias\s+$alias_name=" "$file" | cut -d"'" -f2)
            if [ "$existing_command" == "$command" ]; then
                echo "Alias $alias_name already set up accordingly."
                return
            else
                read -p "Alias $alias_name already exists. Do you want to update it? (y/n) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    # Comment out old alias definition
                    sed -i "s/^alias $alias_name=.*/#&/" "$file"
                    echo "alias $alias_name='$command'" >> "$file"
                    echo "Updated alias $alias_name in $file"
                else
                    echo "Aborting alias update."
                    exit 1
                fi
            fi
        fi
    else
        # Add new alias definition
        echo "alias $alias_name='$command'" >> "$file"
        echo "Alias $alias_name added to $file. Please restart your terminal or source ~/.bashrc."
    fi
}

# Get script path and directory
script_path=$(dirname "$0")/${0##*/}
script_dir=$(dirname "$0")

# Check if script is called with arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 <alias_name> [<command>]"
    echo "Example: $0 b apa.sh"
    exit 1
fi

# Get alias name and command
alias_name="$1"
if [ $# -eq 2 ]; then
    command="$2"
else
    command="$script_path"
fi

# Add absolute path to command if it's a relative path
if [ ! "$command" =~ ^/ ]; then
    command="$script_dir/$command"
fi

# Add alias to .bashrc
add_alias_to_bashrc "$alias_name" "$command"

# Source .bashrc
source "$HOME/.bashrc"
echo "Sourced $HOME/.bashrc successfully."

# Interactive mode
while true; do
    read -p "Enter alias name: " alias_name
    read -p "Enter command: " command
    add_alias_to_bashrc "$alias_name" "$command"
    read -p "Add another alias? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        break
    fi
done