#!/bin/bash
# author: Kilian Lindberg 2024
# co-author and inspiration: everyone & Lama
 license: MIT License

# Brief description of the script's purpose and functionality
# This script adds and manages aliases in the shell configuration file.

# Get the shell configuration file
if [ -n "$ZSH_VERSION" ]; then
    shell_config_file="$HOME/.zshrc"
else
    shell_config_file="$HOME/.bashrc"
fi

# Function to update shell configuration file with new alias or environment variable
update_shell_config() {
    local entry="$1"
    echo "Updating $shell_config_file with entry: $entry"
    if ! grep -qF "$entry" "$shell_config_file"; then
        echo "$entry" >> "$shell_config_file"
        echo "Added $entry to $shell_config_file"
    else
        echo "$entry already exists in $shell_config_file"
    fi
}

# Function to add alias to shell configuration file
add_alias_to_shell_config() {
    local alias_name="$1"
    local command="$2"

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

    # Check if alias is already present in shell configuration file (either uncommented or commented out)
    if grep -qE "^alias\s+$alias_name=|^#.*alias\s+$alias_name=" "$shell_config_file"; then
        if grep -qE "^#.*alias\s+$alias_name=" "$shell_config_file"; then
            # If the alias is commented out, uncomment it and update the command
            sed -i "s/^#*alias $alias_name=.*/alias $alias_name='$command'/" "$shell_config_file"
            echo "Updated alias $alias_name in $shell_config_file"
        else
            existing_command=$(grep -E "^alias\s+$alias_name=" "$shell_config_file" | cut -d"'" -f2)
            if [ "$existing_command" == "$command" ]; then
                echo "Alias $alias_name already set up accordingly."
                return
            else
                read -p "Alias $alias_name already exists. Do you want to update it? (y/n) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    # Comment out old alias definition
                    sed -i "s/^alias $alias_name=.*/#&/" "$shell_config_file"
                    echo >> "$shell_config_file"  # Add a new line
                    echo "alias $alias_name='$command'" >> "$shell_config_file"
                    echo "Updated alias $alias_name in $shell_config_file"
                else
                    echo "Aborting alias update."
                    exit 1
                fi
            fi
        fi
    else
        # Add new alias definition
        echo >> "$shell_config_file"  # Add a new line
        echo "alias $alias_name='$command'" >> "$shell_config_file"
        echo "Alias $alias_name added to $shell_config_file. Please restart your terminal or source $shell_config_file."
    fi
}

# Function to remove alias from shell configuration file
remove_alias_from_shell_config() {
    local alias_name="$1"
    if grep -qE "^alias\s+$alias_name=|^#.*alias\s+$alias_name=" "$shell_config_file"; then
        sed -i "/^alias\s+$alias_name=/d" "$shell_config_file"
        echo "Alias $alias_name removed from $shell_config_file"
    else
        echo "Alias $alias_name does not exist in $shell_config_file"
    fi
}

# Function to list aliases from shell configuration file
list_aliases_from_shell_config() {
    if [ ! -f "$shell_config_file" ]; then
        echo "No $shell_config_file found, exiting!"
        exit 1
    fi
    echo "Available aliases:"
    grep -E "^alias " "$shell_config_file" | cut -d"'" -f2 | sort
}

# Get script path and directory
script_path=$(dirname "$0")/${0##*/}
script_dir=$(dirname "$0")

# Check if script is called with arguments
if [ $# -eq 0 ]; then
    echo "Simple tool to add aliases to your terminal"
    echo "It may try to open the $shell_config_file with code and also its suggested to simply open another terminal for a test run to ensure everythings properly done (as always, care and concern has been applied but there may be scenarios where this tool may not create wishful states)"
    echo "Usage: $0 <alias_name> [<command>]"
    echo "Example: $0 b apa.sh"
    echo ""
    list_aliases_from_shell_config
    exit 0
fi

# Check if script should set up an alias for itself
if ! grep -qF "alias a='$0'" "$shell_config_file"; then
    read -p "Do you want to add an alias 'a' for this script? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        add_alias_to_shell_config "a" "$0"
    fi
fi

# Get alias name and command
alias_name="$1"
if [ $# -eq 2 ]; then
    command="$2"
else
    command="$script_path"
fi

# Add absolute path to command if it's a relative path
if [[ ! "$command" =~ ^/ ]]; then
    command="$script_dir/$command"
fi

# Add alias to shell configuration file
add_alias_to_shell_config "$alias_name" "$command"

# Source shell configuration file
source "$shell_config_file"
echo "Sourced $shell_config_file successfully."

# Interactive mode
while true; do
    read -p "Enter alias name: " alias_name
    read -p "Enter command: " command
    add_alias_to_shell_config "$alias_name" "$command"
    read -p "Add another alias? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        break
    fi
done