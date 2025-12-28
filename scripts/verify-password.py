#!/usr/bin/env python3
import sys
import subprocess
import getpass
import os
import pty
import select

def verify_password(password, username):
    """Verify password using su command with proper stdin handling"""
    try:
        # Create a pseudo-terminal for su to read from
        master, slave = pty.openpty()
        
        # Start su process
        process = subprocess.Popen(
            ['su', '-c', 'true', username],
            stdin=slave,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            preexec_fn=os.setsid
        )
        
        # Close slave fd in parent
        os.close(slave)
        
        # Write password to master
        os.write(master, (password + '\n').encode())
        
        # Wait for process with timeout
        try:
            process.wait(timeout=3)
            result = process.returncode == 0
        except subprocess.TimeoutExpired:
            process.kill()
            result = False
        
        os.close(master)
        return result
        
    except Exception as e:
        # Fallback: try simple approach
        try:
            process = subprocess.Popen(
                ['su', '-c', 'true', username],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            # Send password and close stdin
            process.stdin.write(password + '\n')
            process.stdin.close()
            process.wait(timeout=3)
            return process.returncode == 0
        except:
            return False

if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(1)
    
    password = sys.argv[1]
    username = getpass.getuser()
    
    if verify_password(password, username):
        sys.exit(0)
    else:
        sys.exit(1)


