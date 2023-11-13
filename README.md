# Public Environment Configuration Script

This PowerShell script is a simple tool designed for setting up development environments on public computers, such as those available in libraries. The script facilitates the installation of local copies of essential tools like Python, Git, and Paint.NET, allowing you to work on projects even when you don't have access to a private computer.

## Usage

### Prerequisites

- PowerShell

### Running the Script

1. Open a PowerShell terminal.
2. Run the following command to bypass execution policy:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process
Run the script:
powershell
Copy code
./your_script_name.ps1
Features
Sets up a project directory and a download directory.
Downloads and installs specified packages (e.g., Python, Git, Paint.NET) based on a YAML configuration.
Configures the environment with the required tools for development.
Useful for working on public computers where installing tools might be restricted.
Configuration
Edit the $packages variable in the script to specify the packages you want to install. Example:

powershell
$packages = @{
    'git'       = @{ 'version' = '2.41.0.3' }
    'python'    = @{ 'version' = '3.11.1' }
    'paint.net' = @{ 'version' = '5.0.11' }
}
Notes
The first line Set-ExecutionPolicy Bypass -Scope Process should be executed separately in the PowerShell terminal to override script execution restrictions on public Windows machines.

The script is an example of a PowerShell script and can be extended to handle the installation of more packages by modifying the $packages variable.

Disclaimer
Use this script responsibly and respect the policies of public computers and institutions where you run it.

License
This script is provided under the MIT License.

Replace `your_script_name.ps1` with the actual name of your PowerShell script. Fee
