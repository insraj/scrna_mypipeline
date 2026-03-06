"""
Configuration loader for pipeline scripts.
Reads configuration from config.sh file.
"""
import os
import re
from pathlib import Path

def load_config(config_path=None):
    """Load configuration from config.sh file."""
    if config_path is None:
        # Default to config.sh in same directory
        script_dir = Path(__file__).parent
        config_path = script_dir / "config.sh"
    
    config = {}
    
    with open(config_path) as f:
        for line in f:
            line = line.strip()
            
            # Skip comments and empty lines
            if not line or line.startswith('#'):
                continue
            
            # Parse key=value pairs
            match = re.match(r'^([A-Z_][A-Z0-9_]*)=(.+)$', line)
            if match:
                key = match.group(1)
                value = match.group(2)
                
                # Expand variables in value
                while '${' in value:
                    var_match = re.search(r'\$\{([A-Z_][A-Z0-9_]*)\}', value)
                    if var_match:
                        var_name = var_match.group(1)
                        var_value = config.get(var_name, '')
                        value = value.replace(f'${{{var_name}}}', var_value)
                    else:
                        break
                
                config[key] = value
    
    return config

# Load config when module is imported
CONFIG = load_config()

def get(key, default=None):
    """Get a configuration value."""
    return CONFIG.get(key, default)
