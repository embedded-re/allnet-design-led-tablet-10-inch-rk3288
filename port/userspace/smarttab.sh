# /etc/profile.d/30-smarttab.sh — interactive defaults (login shells: ash and bash)
export LANG=${LANG:-C.UTF-8}
export EDITOR=nano VISUAL=nano PAGER=less LESS=-R
export MANPAGER="less -R"
# unknown TERM from some client? fall back instead of breaking full-screen apps
if [ -n "$TERM" ] && command -v infocmp >/dev/null && ! infocmp "$TERM" >/dev/null 2>&1; then export TERM=xterm-256color; fi
alias ls='ls --color=auto' ll='ls -lah --color=auto' grep='grep --color=auto' ip='ip -color=auto'
