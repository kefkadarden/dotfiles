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
DOTFILES_DIR="$HOME/packages"
BACKUP_DIR="$DOTFILES_DIR/kde-backup"
PROFILE_NAME="hypr-plasma"
EXPORT_FILE="$BACKUP_DIR/$PROFILE_NAME.knsv"

# Ensure script runs from the correct repository root location
mkdir -p "$BACKUP_DIR"

print_status() {
    echo -e "${BLUE}[*] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[✔] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

print_error() {
    echo -e "${RED}[✘] $1${NC}"
}

show_help() {
    echo "Usage: $0 [OPTION]"
    echo "Automate KDE and terminal configuration synchronization using Konsave and Stow."
    echo ""
    echo "Options:"
    echo "  --backup    Freeze current KDE state, export profile, and prepare dotfiles folder."
    echo "  --restore   Install system tools, apply GNU Stow configurations, and import KDE layout."
    echo "  --help      Display this help menu."
}

check_system_deps() {
    print_status "Verifying system packages..."

        # Check and install base requirements from official repositories
    if ! command -v stow &> /dev/null; then
        print_warning "GNU Stow is missing. Installing via pacman..."
        sudo pacman -S --noconfirm stow
    fi

    # Check and install Konsave from CachyOS AUR helper
    if ! command -v konsave &> /dev/null; then
        print_warning "Konsave is missing. Installing via cachyos-yay..."
        if command -v cachyos-yay &> /dev/null; then
            paru -S --noconfirm konsave
        else
            print_error "cachyos-yay package manager not found. Are you on CachyOS?"
            exit 1
        fi
    fi
    print_success "System requirements verified."
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
    konsave -e "$PROFILE_NAME" -d "$HOME/.config/konsave/exports"

        # Move the generated export from standard location into our managed directory repo
    GENERATED_EXPORT=$(find "$HOME/.config/konsave/exports" -name "${PROFILE_NAME}*.knsv" | head -n 1)
    if [ -f "$GENERATED_EXPORT" ]; then
        mv "$GENERATED_EXPORT" "$EXPORT_FILE"
        print_success "KDE setup successfully packed into: $EXPORT_FILE"
    else
        print_error "Failed to locate the exported profile bundle file."
        exit 1
    fi

    print_success "Backup complete! You can now commit and push the contents of '$DOTFILES_DIR' to Git."
}

run_restore() {
    print_status "Initializing recovery pipeline..."

        # Ensure system tools exist on the clean system
    check_system_deps

    # 1. Symlink terminal config folders using GNU Stow
    print_status "Linking terminal dotfiles via GNU Stow..."
    cd "$DOTFILES_DIR"

        # Automatically run stow on every directory folder inside dotfiles, excluding .git and kde-backup
    for dir in */; do
        dir=${dir%/} # strip trailing slash
        if [ "$dir" != "kde-backup" ] && [ "$dir" != ".git" ]; then
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
