echo "Removing ~/.oh-my-zsh"
if [ -d "$HOME/.oh-my-zsh" ]
then
  rm -rf "$HOME/.oh-my-zsh"
fi

echo "Looking for original zsh config..."
if [ -f "$HOME/.zshrc.pre-oh-my-zsh" ] || [ -h "$HOME/.zshrc.pre-oh-my-zsh" ]
then
  echo "Found ~/.zshrc.pre-oh-my-zsh -- Restoring to ~/.zshrc";

  if [ -f "$HOME/.zshrc "] || [ -h "$HOME/.zshrc" ]
  then
    ZSHRC_SAVE=".zshrc.omz-uninstalled-`date +%Y%m%d%H%M%S`";
    echo "Found ~/.zshrc -- Renaming to ~/${ZSHRC_SAVE}";
    mv "$HOME/.zshrc" "$HOME/${ZSHRC_SAVE}";
  fi

  mv "$HOME/.zshrc.pre-oh-my-zsh" "$HOME/.zshrc";

  source "$HOME/.zshrc";
else
  if hash chsh >/dev/null 2>&1
  then
    echo "Switching back to bash"
    chsh -s /bin/bash
  else
    echo "You can edit /etc/passwd to switch your default shell back to bash"
  fi
fi

echo "Thanks for trying out Oh My Zsh. It's been uninstalled."
