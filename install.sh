#!/bin/sh

TREE_DIR="tree"
DOTFILES_PWD="$(pwd -P)"
DOTFILES_PWD="$DOTFILES_PWD/$TREE_DIR"

info() {
	printf " [ \033[00;34m..\033[0m ] $@\n"
}

user () {
	printf "\r [ \033[0;33m?\033[0m ] $@\n"
}

success () {
	printf "\r\033[2K [ \033[00;32mOK\033[0m ] $@\n"
}

fail () {
	printf "\r\033[2K [\033[0;31mFAIL\033[0m] $@\n"
	echo ""
	exit 1
}

link_files () {
	ln -s $1 $2
	success "linked $1 to $2"
}

install_dotfiles() {
	info "installing dotfiles"

	overwrite_all=false
	skip_all=false

	for src in $(find $DOTFILES_PWD -name \*.symlink)
	do
		# find if symlink is in a subdir
		# - get the real symlink path
		dest_dir="$(realpath $(dirname "$src"))"
		# - subsitute the symlink path with the tree path
		#   cause the tree path is the reference to reproduce
		#   in our $HOME
		# ex : path/to/tree/mydir/myfile.symlink -> $HOME/mydir/myfile.symlink
		dest_dir="${dest_dir#${DOTFILES_PWD}}"

		if [ ! -z "$dest_dir" ]; then
			# if $dest_dir is not empty 
			# create the subdir
			mkdir -p "${HOME}${dest_dir}" || fail "cannot create $dest_dir"
		fi

		dest="${HOME}${dest_dir}/$(basename ${src%.*})"

		# $dest already exist
		if [ -f $dest ] || [ -d $dest ]
		then
			skip=false
			overwrite=false

			if [ "$overwrite_all" == "false" ] && [ "$skip_all" == "false" ]
			then
				user "File already exists: $(basename \"${src%.*}\"), what do you want to do ? [s]kip, [S]kip all, [o]verwrite, [O]verwrite all"
				read -n 1 action
				
				case "$action" in
					s )
						skip=true;;
					S )
						skip_all=true;;
					o )
						overwrite=true;;
					O )
						overwrite_all=true;;
					* )
						;;
				esac
			fi

			if [ "$overwrite" == "true" ] || [ "$overwrite_all" == "true" ]
			then
				rm -rf $dest
				success "removed $dest"
			fi
			
			if [ "$skip" == "false" ] && [ "$skip_all" == "false" ]
			then
				link_files $src $dest
			else
				success "skipped $src"
			fi
			
		else
			link_files $src $dest
		fi

	done
}

install_dotfiles

echo ''
success "All installed!"
