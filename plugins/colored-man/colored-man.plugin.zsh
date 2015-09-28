if [ "$OSTYPE[0,7]" = "solaris" ]
then
    if [ ! -x ${HOME}/bin/nroff ]
    then
        mkdir -p ${HOME}/bin
        cat > ${HOME}/bin/nroff <<EOF
#!/bin/sh
if [ -n "\$_NROFF_U" -a "\$1,\$2,\$3" = "-u0,-Tlp,-man" ]; then
    shift
    exec /usr/bin/nroff -u\${_NROFF_U} "\$@"
fi
#-- Some other invocation of nroff
exec /usr/bin/nroff "\$@"
EOF
    chmod +x ${HOME}/bin/nroff
    fi
fi

# This works by overriding parts of the termcap definition just
# for `less`
() {
  local context=:omz:plugins:colored-man
  zstyle $context mb '$fg[red]'          # begin "blink"
  zstyle $context md '$fg[red]'          # begin "bold"
  zstyle $context so '$fg_bold[yellow]$bg[blue]'  # begin standout
  zstyle $context se '$reset_color'      # end standout
  zstyle $context us '$fg_bold[green]$termcap[us]'   # start "underline"
  zstyle $context ue '$reset_color'      # end "underline"
  zstyle $context me '$reset_color'      # end all modes
}

man() {
    local _mb _md _me _se _so _ue _us cap str
    local -A style

    for cap ( mb md so se us ue me ); do
      zstyle -s :omz:plugins:colored-man $cap str
      eval "style[$cap]=$str"
    done

    env \
      LESS_TERMCAP_mb=$style[mb] \
      LESS_TERMCAP_md=$style[md] \
      LESS_TERMCAP_me=$style[me] \
      LESS_TERMCAP_se=$style[se] \
      LESS_TERMCAP_so=$style[so] \
      LESS_TERMCAP_ue=$style[ue] \
      LESS_TERMCAP_us=$style[us] \
      PAGER=/usr/bin/less \
      _NROFF_U=1 \
      PATH=${HOME}/bin:${PATH} \
                     man "$@"
}
