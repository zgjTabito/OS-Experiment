#!/usr/bin/env bash
set -euo pipefail

# Programs to run in the in-guest shell (order matters)
programs=(
  # exit
  # forktest
  # hello
  # matrix
  # pgdir
  # priority
  # sleep
  # sleepkill
  # softint
  # spin
  # waitkill
  # yield
)

# Adjust to the directory that contains Makefile for lab8
LAB_DIR="${LAB_DIR:-$(pwd)}"

if [[ ! -d "$LAB_DIR" ]]; then
  echo "LAB_DIR=$LAB_DIR not found" >&2
  exit 1
fi

cd "$LAB_DIR"

# Expect script embedded below. It will:
#  1) spawn `make qemu`
#  2) wait for the user shell prompt `$ `
#  3) sequentially run each program, waiting for prompt each time
#  4) exit the guest when done

expect <<'EOF'
set timeout 120
set programs [list \
  exit\
  forktest hello matrix pgdir priority \
  sleep sleepkill softint spin waitkill yield]

spawn make qemu

# Wait for the shell prompt inside the guest
expect {
    -re {\$ $} {}
    timeout { puts "Timed out waiting for shell prompt"; exit 1 }
}

foreach p $programs {
    send -- "$p\r"
    # Wait for next prompt; allow some output from the test
    expect {
        -re {\$ $} {}
        timeout { puts "Timed out waiting after $p"; exit 1 }
    }
}

# Exit the guest shell to stop qemu cleanly
send -- "exit\r"
expect eof
EOF
