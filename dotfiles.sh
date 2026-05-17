#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define color codes for pretty output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configurations
DOTFILES_DIR="$HOME/packages/dotfiles"
BACKUP_DIR="$DOTFILES_DIR/kde-backup"
PROFILE_NAME="hypr-plasma"
EXPORT_FILE="$BACKUP_DIR/$PROFILE_NAME.knsv"
EXPORT_DIR="$HOME/.config/konsave/exports/"
# Ensure script runs from the correct repository root location
mkdir -p "${BACKUP_DIR}"

print_status() {
    echo -e "${BLUE}[*] ($1)${NC}"
}

print_success() {
    echo -e "${GREEN}[✔] ($1)${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] ($1)${NC}"
}

print_error() {
    echo -e "${RED}[✘] ($1)${NC}"
}

show_help() {
    echo "Usage: $0 [OPTION]"
    echo "Automate KDE and terminal configuration synchronization with Git syncing."
    echo ""
    echo "Options:"
    echo "  --backup    Freeze current state, export profile, commit, and push to Git."
    echo "  --restore   Pull latest Git changes, link via Stow, and import KDE layout."
    echo "  --help      Display this help menu."
}

check_system_deps() {
    print_status "Verifying system packages..."
    
    # Verify core utilities
    for cmd in stow git; do
        if ! command -v $cmd &> /dev/null; then
            print_warning "$cmd is missing. Installing via pacman..."
            sudo pacman -S --noconfirm $cmd
        fi
    done

    # Check and install Konsave from CachyOS AUR helper
    if ! command -v konsave &> /dev/null; then
        print_warning "Konsave is missing. Installing via cachyos-yay..."
        if command -v cachyos-yay &> /dev/null; then
            cachyos-yay -S --noconfirm konsave
        else
            print_error "cachyos-yay package manager not found. Are you on CachyOS?"
            exit 1
        fi
    fi
    print_success "System requirements verified."
}

check_git_repo() {
    cd "$DOTFILES_DIR"
    cd ..
    if [ ! -d ".git" ]; then
        print_warning "Directory is not a Git repository. Initializing local repo..."
        git init
        print_warning "Remember to add a remote path later: git remote add origin <your-repo-url>"
    fi
}

git_push_changes() {
    check_git_repo
    print_status "Checking Git tracking status..."
    
    # Verify if a remote tracking branch actually exists before attempting a network push
    if ! git remote | grep -q 'origin'; then
        print_warning "No Git remote upstream found ('origin'). Skipping network push."
        print_warning "Your files are saved locally. Connect a remote to backup to the cloud."
        return
    fi

    # Check if there are changes to commit
    if [ -n "$(git status --porcelain)" ]; then
        print_status "Staging configuration modifications..."
        git add .
        
        TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
        print_status "Committing changes..."
        git commit -m "dotfiles: automated backup sync ($TIMESTAMP)"
        
        print_status "Pushing updates to remote branch..."
        # Extract the current branch name dynamically
        CURRENT_BRANCH=$(git branch --show-current)
        git push origin "$CURRENT_BRANCH"
        print_success "Dotfiles safely backed up to the cloud repository!"
    else
        print_success "No local configuration changes detected. Git workspace is completely clean."
    fi
}

git_pull_changes() {
    check_git_repo
    if git remote | grep -q 'origin'; then
        print_status "Fetching latest configuration files from cloud repository..."
        # Safely pull to avoid overriding local uncommitted changes
        if ! git pull --rebase origin "$(git branch --show-current)"; then
            print_error "Git pull failed. Check for merge conflicts or network problems."
            exit 1
        fi
        print_success "Dotfiles synchronization up to date."
    else
        print_warning "No Git remote found ('origin'). Skipping update check."
    fi
}

run_backup() {
    print_status "Initializing backup pipeline..."
    
    # Ensure system tools exist
    check_system_deps

    # Clear out any old profiles inside Konsave directory to prevent collisions
    if konsave -l | grep -q "$PROFILE_NAME"; then
        print_status "Removing outdated internal Konsave profile..."
        konsave -r "$PROFILE_NAME"
    fi

    # Save current active configuration state
    print_status "Capturing live desktop snapshot..."
    konsave -s "$PROFILE_NAME"

    # Export configuration bundle file out to our dotfiles workspace
    print_status "Exporting profile to directory archive..."
    rm -f "$EXPORT_FILE"
    konsave -e "$PROFILE_NAME" -d "$EXPORT_DIR"
    
    # Move the generated export from standard location into our managed directory repo
    GENERATED_EXPORT=$(find "$EXPORT_DIR" -name "${PROFILE_NAME}*.knsv" | head -n 1)
    if [ -f "$GENERATED_EXPORT" ]; then
        mv "$GENERATED_EXPORT" "$EXPORT_FILE"
        print_success "KDE setup successfully packed into: $EXPORT_FILE"
    else
        print_error "Failed to locate the exported profile bundle file."
        exit 1
    fi

    # Run the Git sync process
    git_push_changes
    print_success "Backup lifecycle complete!"
}

run_restore() {
    print_status "Initializing recovery pipeline..."
    
    # Ensure system tools exist on the clean system
    check_system_deps

    # Bring down the latest code changes from the cloud
    git_pull_changes

    # 1. Symlink terminal config folders using GNU Stow
    print_status "Linking terminal dotfiles via GNU Stow..."
    cd "$DOTFILES_DIR"
    
    # Automatically run stow on every directory folder inside dotfiles, excluding .git and kde-backup
    for dir in */; do
        dir=${dir%/} # strip trailing slash
        if [ "$dir" != "kde-backup" ] && [ "$dir" != ".git" ] && [ "$dir" != "scripts" ]; then
            print_status "Stowing package configuration: $dir"
            stow "$dir"
        fi
    done

    # 2. Re-import desktop layout profile
    if [ -f "$EXPORT_FILE" ]; then
        print_status "Importing $PROFILE_NAME.knsv layout snapshot into system memory..."
        
        # Overwrite internal database record cleanly if profile name already exists
        if konsave -l | grep -q "$PROFILE_NAME"; then
            konsave -r "$PROFILE_NAME"
        fi

        konsave -i "$EXPORT_FILE"
        
        print_status "Applying visual profile and workspace settings..."
        konsave -a "$PROFILE_NAME"
        print_success "KDE desktop environment restored completely!"
        print_warning "Note: A system logout or reboot is highly recommended to finalize tiling states."
    else
        print_error "Critical archive file missing: Could not find '$EXPORT_FILE'"
        exit 1
    fi
}

# Core Argument Router Logic
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

case "$1" in
    --backup)
        run_backup
        ;;
    --restore)
        run_restore
        ;;
    --help|-h)
        show_help
        ;;
    *)
        print_error "Invalid option identifier provided: $1"
        show_help
        exit 1
        ;;
esac
