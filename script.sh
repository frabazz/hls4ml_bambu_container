#!/bin/bash
# Script to create and set up the bambu-env conda environment

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/environment.yml"

echo "=== Setting up bambu-env conda environment ==="

# Check if conda is available
if ! command -v conda &> /dev/null; then
    echo "Conda not found. Checking for miniforge..."
    
    # Check if miniforge is installed but not in PATH
    if [ -d "$HOME/miniforge" ]; then
        echo "Found miniforge at $HOME/miniforge, adding to PATH..."
        export PATH="$HOME/miniforge/bin:$PATH"
    elif [ -d "$HOME/conda" ]; then
        echo "Found conda at $HOME/conda, adding to PATH..."
        export PATH="$HOME/conda/bin:$PATH"
    elif [ -d "$HOME/anaconda3" ]; then
        echo "Found anaconda at $HOME/anaconda3, adding to PATH..."
        export PATH="$HOME/anaconda3/bin:$PATH"
    elif [ -d "$HOME/miniconda3" ]; then
        echo "Found miniconda at $HOME/miniconda3, adding to PATH..."
        export PATH="$HOME/miniconda3/bin:$PATH"
    else
        echo "Conda/miniforge not found. Would you like to install miniforge? (y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo "Installing miniforge..."
            wget -q https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O /tmp/miniforge.sh
            bash /tmp/miniforge.sh -b -p "$HOME/miniforge"
            rm /tmp/miniforge.sh
            export PATH="$HOME/miniforge/bin:$PATH"
            echo "Miniforge installed. Please run 'conda init bash' and restart your shell, or source $HOME/miniforge/bin/activate"
        else
            echo "Please install conda/miniforge first and run this script again."
            exit 1
        fi
    fi
fi

# Verify conda is now available
if ! command -v conda &> /dev/null; then
    echo "Error: conda still not found. Please install conda/miniforge and try again."
    exit 1
fi

echo "Conda found: $(conda --version)"

# Configure conda
echo "Configuring conda..."
conda config --set channel_priority strict

# Check if environment already exists
if conda env list | grep -q "^bambu-env "; then
    echo "Environment 'bambu-env' already exists."
    echo "Would you like to remove it and recreate? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Removing existing environment..."
        conda env remove -n bambu-env -y
    else
        echo "Keeping existing environment. To update it, run:"
        echo "  conda env update -n bambu-env -f $ENV_FILE"
        exit 0
    fi
fi

# Create the environment
echo "Creating conda environment 'bambu-env' from $ENV_FILE..."
conda env create -n bambu-env -f "$ENV_FILE"

# Clean up
echo "Cleaning up conda cache..."
conda clean --all -y

# Install hls4ml in development mode
HLS4ML_DIR="${SCRIPT_DIR}/hls4ml"
if [ -d "$HLS4ML_DIR" ]; then
    echo ""
    echo "Installing hls4ml in development mode..."
    conda run -n bambu-env bash -c "cd '$HLS4ML_DIR' && pip install .[da,testing,sr,optimization]"
    echo "hls4ml installation complete!"
else
    echo "Warning: hls4ml directory not found at $HLS4ML_DIR"
fi

# Install Bambu HLS tool
echo ""
echo "=== Installing Bambu HLS tool ==="
BAMBU_URL="https://release.bambuhls.eu/bambu-latest.AppImage"
BAMBU_INSTALL_DIR="${HOME}/.local/bin"
BAMBU_APPIMAGE="${BAMBU_INSTALL_DIR}/bambu.AppImage"
BAMBU_SYMLINK="${BAMBU_INSTALL_DIR}/bambu"

# Create installation directory if it doesn't exist
mkdir -p "$BAMBU_INSTALL_DIR"

# Check if bambu is already installed
if [ -f "$BAMBU_APPIMAGE" ] || [ -f "$BAMBU_SYMLINK" ]; then
    echo "Bambu HLS tool already exists at $BAMBU_APPIMAGE or $BAMBU_SYMLINK"
    echo "Would you like to reinstall it? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Removing existing Bambu installation..."
        rm -f "$BAMBU_APPIMAGE" "$BAMBU_SYMLINK"
    else
        echo "Keeping existing Bambu installation."
        BAMBU_INSTALLED=true
    fi
fi

# Download and install Bambu if not already installed
if [ "${BAMBU_INSTALLED:-false}" != "true" ]; then
    echo "Downloading Bambu HLS AppImage from $BAMBU_URL..."
    if command -v wget &> /dev/null; then
        wget -q --show-progress "$BAMBU_URL" -O "$BAMBU_APPIMAGE"
    elif command -v curl &> /dev/null; then
        curl -L --progress-bar "$BAMBU_URL" -o "$BAMBU_APPIMAGE"
    else
        echo "Error: Neither wget nor curl found. Please install one of them to download Bambu."
        exit 1
    fi
    
    # Make the AppImage executable
    chmod +x "$BAMBU_APPIMAGE"
    
    # Create a symlink for easier access
    ln -sf "$BAMBU_APPIMAGE" "$BAMBU_SYMLINK"
    
    echo "Bambu HLS tool installed successfully!"
fi

# Verify installation and add to PATH
if [ -x "$BAMBU_APPIMAGE" ] || [ -x "$BAMBU_SYMLINK" ]; then
    echo "Bambu HLS tool is ready at: $BAMBU_SYMLINK"
    
    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":${HOME}/.local/bin:"* ]]; then
        echo ""
        echo "Adding ~/.local/bin to PATH..."
        
        # Detect shell and determine config file
        SHELL_CONFIG=""
        if [ -n "$ZSH_VERSION" ]; then
            SHELL_CONFIG="${HOME}/.zshrc"
        elif [ -n "$BASH_VERSION" ]; then
            SHELL_CONFIG="${HOME}/.bashrc"
        else
            # Try to detect from $SHELL environment variable
            case "$SHELL" in
                *zsh)
                    SHELL_CONFIG="${HOME}/.zshrc"
                    ;;
                *bash)
                    SHELL_CONFIG="${HOME}/.bashrc"
                    ;;
                *)
                    # Default to .bashrc if we can't determine
                    SHELL_CONFIG="${HOME}/.bashrc"
                    ;;
            esac
        fi
        
        # Check if the path export already exists in the config file
        PATH_EXPORT='export PATH="$HOME/.local/bin:$PATH"'
        if [ -f "$SHELL_CONFIG" ]; then
            if grep -Fxq "$PATH_EXPORT" "$SHELL_CONFIG" 2>/dev/null; then
                echo "PATH export already exists in $SHELL_CONFIG"
            else
                echo "" >> "$SHELL_CONFIG"
                echo "# Added by setup_bambu_env.sh - Bambu HLS tool" >> "$SHELL_CONFIG"
                echo "$PATH_EXPORT" >> "$SHELL_CONFIG"
                echo "Added PATH export to $SHELL_CONFIG"
                echo "Please run 'source $SHELL_CONFIG' or restart your terminal to use 'bambu' command."
            fi
        else
            # Create the config file if it doesn't exist
            echo "# Added by setup_bambu_env.sh - Bambu HLS tool" > "$SHELL_CONFIG"
            echo "$PATH_EXPORT" >> "$SHELL_CONFIG"
            echo "Created $SHELL_CONFIG and added PATH export"
            echo "Please run 'source $SHELL_CONFIG' or restart your terminal to use 'bambu' command."
        fi
        
        # Also add to current session PATH
        export PATH="${HOME}/.local/bin:$PATH"
        echo "PATH updated for current session."
    else
        echo "~/.local/bin is already in PATH."
    fi
else
    echo "Warning: Bambu installation verification failed."
fi

echo ""
echo "=== Environment setup complete! ==="
echo ""
echo "To activate the environment, run:"
echo "  conda activate bambu-env"
echo ""
echo "Or if conda is not initialized in your shell:"
echo "  source $(conda info --base)/etc/profile.d/conda.sh"
echo "  conda activate bambu-env"
