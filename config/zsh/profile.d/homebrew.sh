# Homebrew

# * Verify brew is installed
# * Intialize brew for shell environment if interactive

export HOMEBREW_NO_EMOJI=1
export HOMEBREW_DOWNLOAD_CONCURRENCY=auto

if [[ $- == *i* ]]; then
  if [ -d /opt/homebrew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -d /home/linuxbrew/.linuxbrew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
fi
