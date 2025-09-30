# Configure readline
export INPUTRC="${XDG_CONFIG_HOME}/readline/inputrc"

# =====================================
# Load profile modules
# =====================================
if [[ -d "${ZDOTDIR}/profile.d" ]]; then
  for profile in "${ZDOTDIR}"/profile.d/*.sh(N); do
    source "$profile"
  done
  unset profile
fi
