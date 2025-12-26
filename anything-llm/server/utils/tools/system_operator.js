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
          exec(command, { cwd: 'C:\\\\AI_Agent_Workspace\\\\AnythingLLM-Full-Agent-mode\\\\anything-llm\\\\server' }, (error, stdout, stderr) => {
            if (error) resolve(\Error: \\\nStderr: \\);
            else resolve(\Output: \\);
          });
        });
      }
      if (action === 'write_file') {
        const target = path.resolve(file_path);
        fs.mkdirSync(path.dirname(target), { recursive: true });
        fs.writeFileSync(target, content, 'utf8');
        return \File written to \\;
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
      return \System Error: \\;
    }
  }
};

module.exports = SystemOperator;
