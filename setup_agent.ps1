<#
.SYNOPSIS
    AnythingLLM "Bare Metal" CLI Agent Setup
.DESCRIPTION
    Automates the cloning, building, and configuration of AnythingLLM on Windows.
    Injects the "System Operator" tool for filesystem/CLI access.
    Configures LanceDB for automatic, zero-config vector storage.
.NOTES
    Role: Copilot Engineer
    Target: Windows / PowerShell
#>

$ErrorActionPreference = "Stop"

# --- CONFIGURATION ---
$WORK_DIR = "C:\AI_Agent_Workspace\AnythingLLM-Full-Agent-mode"
$REPO_URL = "https://github.com/Mintplex-Labs/anything-llm.git"
$STORAGE_DIR = "$WORK_DIR\storage"
$SERVER_PORT = 3001

Write-Host ">>> INITIALIZING 'CLI DREAM' PROTOCOL..." -ForegroundColor Cyan

# 1. PREREQUISITE CHECKS
Write-Host "[-] Checking prerequisites..."
try {
    $nodeVer = node -v
    Write-Host "    NodeJS found: $nodeVer" -ForegroundColor Green
} catch {
    Write-Error "NodeJS is not installed. Please install Node v18+ first."
}

try {
    $yarnVer = yarn -v
    Write-Host "    Yarn found: $yarnVer" -ForegroundColor Green
} catch {
    Write-Host "    Yarn not found. Installing via npm..." -ForegroundColor Yellow
    npm install --global yarn
}

# 2. WORKSPACE CREATION
if (-not (Test-Path $WORK_DIR)) {
    Write-Host "[-] Creating workspace at $WORK_DIR..."
    New-Item -ItemType Directory -Force -Path $WORK_DIR | Out-Null
}
Set-Location $WORK_DIR

# 3. CLONE REPOSITORY
if (-not (Test-Path "$WORK_DIR\anything-llm")) {
    Write-Host "[-] Cloning AnythingLLM repository..." -ForegroundColor Cyan
    git clone $REPO_URL
} else {
    Write-Host "[-] Repository exists. Pulling latest..." -ForegroundColor Cyan
    Set-Location "$WORK_DIR\anything-llm"
    git pull
}

Set-Location "$WORK_DIR\anything-llm"

# 4. SERVER SETUP & SMART VECTOR DB
Write-Host "[-] Configuring Server & Smart Vector DB (LanceDB)..." -ForegroundColor Cyan
Set-Location "server"

# Install Dependencies
yarn install

# Generate ENV File
$EnvContent = @"
PORT=$SERVER_PORT
JWT_SECRET='cli-dream-secret-$(Get-Random)'
STORAGE_DIR='$STORAGE_DIR'
# Smart Vector DB Configuration (No Docker required)
VECTOR_DB='lancedb'
"@

Set-Content -Path ".env" -Value $EnvContent
Write-Host "    .env file generated with LanceDB configuration." -ForegroundColor Green

# Database Migrations
Write-Host "[-] Running Prisma Migrations..."
npx prisma generate
npx prisma migrate deploy

# 5. INJECTING THE "SYSTEM OPERATOR" TOOL (The CLI Agent Logic)
Write-Host "[-] Injecting System Operator Tool (CLI Capabilities)..." -ForegroundColor Magenta

$ToolPath = "$WORK_DIR\anything-llm\server\utils\tools"
if (-not (Test-Path $ToolPath)) { New-Item -ItemType Directory -Force -Path $ToolPath | Out-Null }

$SystemOperatorCode = @"
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const SystemOperator = {
  name: 'system_operator',
  description: 'CRITICAL: Executes shell commands or manipulates files. Use ONLY when specifically asked to run commands or write code to disk.',
  parameters: {
    type: 'object',
    properties: {
      action: {
        type: 'string',
        enum: ['exec', 'write_file', 'read_file', 'list_dir'],
        description: 'The system action to perform.'
      },
      command: {
        type: 'string',
        description: 'Shell command to run (e.g., "npm install", "dir").'
      },
      file_path: {
        type: 'string',
        description: 'Absolute or relative path.'
      },
      content: {
        type: 'string',
        description: 'File content to write.'
      }
    },
    required: ['action']
  },
  func: async ({ action, command, file_path, content }) => {
    try {
      if (action === 'exec') {
        if (!command) return 'No command provided.';
        return new Promise((resolve) => {
          exec(command, { cwd: '$((Get-Location).Path -replace "\\", "\\\\")' }, (error, stdout, stderr) => {
            if (error) resolve(\`Error: \${error.message}\\nStderr: \${stderr}\`);
            else resolve(\`Output: \${stdout}\`);
          });
        });
      }
      if (action === 'write_file') {
        const target = path.resolve(file_path);
        fs.mkdirSync(path.dirname(target), { recursive: true });
        fs.writeFileSync(target, content, 'utf8');
        return \`File written to \${target}\`;
      }
      if (action === 'read_file') {
        if (!fs.existsSync(file_path)) return 'File not found.';
        return fs.readFileSync(file_path, 'utf8');
      }
      if (action === 'list_dir') {
        return fs.readdirSync(file_path || '.').join('\\n');
      }
      return 'Unknown action.';
    } catch (e) {
      return \`System Error: \${e.message}\`;
    }
  }
};

module.exports = SystemOperator;
"@

Set-Content -Path "$ToolPath\system_operator.js" -Value $SystemOperatorCode
Write-Host "    system_operator.js injected successfully." -ForegroundColor Green

# 6. FRONTEND BUILD
Set-Location "$WORK_DIR\anything-llm\frontend"
Write-Host "[-] Building Frontend (This may take a moment)..." -ForegroundColor Cyan

# Configure Frontend Env
Set-Content -Path ".env" -Value "VITE_API_BASE='/api'"

yarn install
yarn build

# Copy Dist to Server Public
Write-Host "[-] Deploying Frontend to Server..."
if (Test-Path "$WORK_DIR\anything-llm\server\public") { Remove-Item -Recurse -Force "$WORK_DIR\anything-llm\server\public" }
Copy-Item -Recurse -Force "dist" "$WORK_DIR\anything-llm\server\public"

# 7. COMPLETION
Write-Host "--------------------------------------------------------" -ForegroundColor Green
Write-Host ">>> ARCHITECTURE DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "--------------------------------------------------------"
Write-Host "1. Codebase is at: $WORK_DIR\anything-llm"
Write-Host "2. Vector DB is set to local (LanceDB) - No configs needed."
Write-Host "3. CLI Tool file created at: $ToolPath\system_operator.js"
Write-Host ""
Write-Host ">>> REQUIRED MANUAL STEP (The 'Wire-Up'):" -ForegroundColor Yellow
Write-Host "To enable the tool, you must edit 'server/utils/aiProviders/index.js' (or similar depending on version)"
Write-Host "and import the SystemOperator we just created, adding it to the tools array."
Write-Host ""
Write-Host ">>> TO START THE SERVER:"
Write-Host "cd $WORK_DIR\anything-llm\server"
Write-Host "node index.js"
Write-Host "--------------------------------------------------------"
