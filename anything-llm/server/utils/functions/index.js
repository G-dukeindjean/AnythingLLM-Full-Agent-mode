const SystemOperator = require('../tools/system_operator');

// Export all available tools/functions
// This array/object is where tools are registered for use by the AI agent
const functionList = [
  SystemOperator
];

// Alternative export pattern (if the codebase uses a different structure)
const validTools = {
  system_operator: SystemOperator
};

// Export both patterns to ensure compatibility
module.exports = {
  functionList,
  validTools,
  SystemOperator
};

