# RooFlow

A fork of [GreatScottyMac's RooFlow](https://github.com/GreatScottyMac/RooFlow) optimized for Amazon Brazil workspace environments and featuring improved setup processes.

[![Roo Code](https://img.shields.io/badge/VS%20Code-Extension-blue.svg)](https://github.com/RooVetGit/Roo-Code)
[![RooFlow](https://img.shields.io/badge/View%20Original-GitHub-lightgrey.svg)](https://github.com/GreatScottyMac/RooFlow)

## 🔹 Key Enhancements

This fork builds on the excellent foundation of RooFlow with several key improvements:

- **Brazil Workspace Integration**: Native support for Brazil 
- **Simplified Setup Process**: Single script installation with both local and remote repository modes
- **Workspace Detection**: Automatic identification of Brazil workspaces

## 🔹 Installation

### One-Line Setup

The easiest way to install RooFlow in your environment is with this one-line command:

```bash
curl -s https://raw.githubusercontent.com/vinodismyname/RooFlow/refs/heads/main/config/setup-roo.sh | bash -s -- https://github.com/vinodismyname/RooFlow.git
```

### Creating an Alias

For even easier access, you can create an alias in your shell configuration:

```bash
# Add to your ~/.bashrc, ~/.zshrc, or equivalent:
alias setup-rooflow='curl -s https://raw.githubusercontent.com/vinodismyname/RooFlow/refs/heads/main/config/setup-roo.sh | bash -s -- https://github.com/vinodismyname/RooFlow.git'
```

After adding this alias and reloading your shell configuration (`source ~/.bashrc` or `source ~/.zshrc`), you can simply run:

```bash
setup-rooflow
```

### Manual Setup Options

If you prefer more control, you can also:

1. Download the setup script:
```bash
curl -o setup-roo.sh https://raw.githubusercontent.com/vinodismyname/RooFlow/refs/heads/main/config/setup-roo.sh
chmod +x setup-roo.sh
```

2. Run with options:
```bash
# Local mode (using local files)
./setup-roo.sh

# Remote mode (clone from repository)
./setup-roo.sh https://github.com/vinodismyname/RooFlow.git

# Force override existing settings
./setup-roo.sh https://github.com/vinodismyname/RooFlow.git --override
```

### Setup Options

- `--override`: Force overwrite of existing .roo directory
- `--help`: Show usage information

## 🔹 Amazon Brazil Integration

This fork adds specialized features for Amazon internal development environments:

### Brazil Workspace Guidelines

A  YAML reference is included that provides Roo Code with extensive knowledge about:

- Brazil package structure and configuration
- Essential Brazil commands for workspace management
- Build system configuration
- Testing frameworks
- Common issues and solutions

This allows Roo Code to provide better assistance when working in Amazon Brazil environments.

### Automatic Workspace Context

When operating inside a Brazil workspace, system prompts are automatically populated with:

- Brazil workspace root location
- Available packages in the workspace
- Build system configuration
- Reference to the included guidelines

## 🔹 System Configuration

The enhanced system prompt configuration is more flexible and adapts to your environment:

```yaml
system_information:
  os: "macOS 14.4.1"
  shell: "bash"
  home_directory: "/Users/username"
  working_directory:
    # Brazil workspace specific information when detected
    workspace_guidelines: "/path/to/brazil-workspace-guidelines.yml"
    brazil_workspace_root: "/path/to/workspace"
    brazil_workspace_packages:
      package1: "/path/to/workspace/src/package1"
      package2: "/path/to/workspace/src/package2"
  initial_context: "Recursive file list in working directory provided in environment_details"
```

## 🔹 Directory Structure

Your project structure will look like this after setup:

```
project-root/
├── .roo/
│    ├── system-prompt-architect
│    ├── system-prompt-ask
│    ├── system-prompt-code
│    ├── system-prompt-debug
│    ├── system-prompt-test
│    └── brazil-workspace-guidelines.yml (if in Brazil workspace)
├── .clinerules-architect
├── .clinerules-code
├── .clinerules-ask
├── .clinerules-debug
├── .clinerules-test
├── .rooignore
├── .roomodes
├── memory-bank/ (created automatically)
│    ├── activeContext.md
│    ├── decisionLog.md
│    ├── productContext.md
│    ├── progress.md
│    └── systemPatterns.md
└── projectBrief.md (optional)
```

## 🔹 Basic Usage

The core functionality remains consistent with the original RooFlow. For detailed information on the Memory Bank system and its features, please refer to the [original RooFlow repository](https://github.com/GreatScottyMac/RooFlow).

### Brazil-Specific Commands

When working in a Brazil workspace, Roo Code will have access to key Brazil commands and can help with:

- Creating and managing Brazil workspaces
- Building packages with various options
- Resolving dependency conflicts
- Executing tests with specific configurations
- Navigating package structures


## 🔹 Acknowledgements

This project is a fork of [GreatScottyMac's RooFlow](https://github.com/GreatScottyMac/RooFlow), which provides the core Memory Bank system and AI-assisted development framework. The enhancements in this fork focus on Amazon Brazil workspace integration and improved setup processes.
