Gitploy is an interactive, terminal-based PowerShell script designed to streamline the process of initializing, configuring, committing, and pushing local directories to GitHub. 

Whether you are pushing a small project or a massive folder with thousands of files, Gitploy handles the boilerplate Git commands, optimizes memory buffers for large commits, and interfaces directly with the GitHub CLI to create repositories on the fly.

## Features

* **Interactive TUI**: Navigate setup options entirely using your keyboard arrows.
* **Auto-Initialization**: Detects if your folder is already a Git repository and initializes it if necessary.
* **Dynamic Repository Management**: Create new repositories (Public or Private) directly from the terminal or link to an existing GitHub repository.
* **Smart Naming**: Defaults the repository name to the script's filename, but allows you to override it interactively.
* **Large Payload Optimization**: Pre-configures Git memory buffers and compression to handle massive initial commits without timing out.

## Prerequisites

Before using Gitploy, ensure you have the following installed on your Windows machine:

1. **Git**: Standard Git version control.
2. **GitHub CLI (gh)**: Required for creating and managing repositories remotely.
   * Install via Winget: `winget install --id GitHub.cli`
   * Authenticate your account: Run `gh auth login` before your first use.

## Usage

1. Copy `Gitploy.ps1` into the root directory of the project you want to upload.
2. Open PowerShell or Windows Terminal in that directory.
3. Run the script:
   ```powershell
   .\\Gitploy.ps1