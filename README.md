# .system-config


# Terminal Setup (Wezterm)

## Install Wezterm
```
brew install --cask wezterm
```
First create the config file:
```
touch ~/.wezterm.lua
```
add code from root/wezterm.lua to ~/.wezterm.lua 


## Install Powerlevel 10k
brew install powerlevel10k


### zsh-autosuggestions
brew install zsh-autosuggestions

### zsh-syntax-highlighting
brew install zsh-syntax-highlighting


### tldr
```
brew install tlrc
```
```
tldr eza
```
### eza (better ls)
```
brew install eza
```


### fzf (fuzzy finder)
```
brew install fzf
```
Example 	Description
CTRL-t 	Look for files and directories
CTRL-r 	Look through command history
Enter 	Select the item
Ctrl-j or Ctrl-n or Down arrow 	Go down one result
Ctrl-k or Ctrl-p or Up arrow 	Go up one result
Tab 	Mark a result
Shift-Tab 	Unmark a result

### fd
brew install fd

### fzf-git
git clone https://github.com/junegunn/fzf-git.sh.git

Keybind 	Description
CTRL-GF 	Look for git files with fzf
CTRL-GB 	Look for git branches with fzf



### bat (cat alternative)
```
brew install bat
```


### git-delta
```
brew install git-delta
```
git show 


### tree
```
brew install tree
```