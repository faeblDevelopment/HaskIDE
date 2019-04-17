# ===================== GIT BASH EXTENSION ============================
# Credits: 
# I found this on Stackoverflow a long time ago but forgot to write
# down the link to the post for giving credits.
# If you encounter your code here and wish to be mentioned in the 
# credits, please open an issue on github, including your information
# and possibly a link to the stackoverflow post
# Didn't want to take your credit away ;)
# Thanks to the anonymous source :D


function parse_git_branch() {
        BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
        if [ ! "${BRANCH}" == "" ]
        then
                STAT=`parse_git_dirty`
                echo "[${BRANCH}${STAT}]"
        else
                echo ""
        fi
}

# get current status of git repo
function parse_git_dirty {
        status=`git status 2>&1 | tee`
        dirty=`echo -n "${status}" 2> /dev/null | grep "modified:" &> /dev/null; echo "$?"`
        untracked=`echo -n "${status}" 2> /dev/null | grep "Untracked files" &> /dev/null; echo "$?"`
        ahead=`echo -n "${status}" 2> /dev/null | grep "Your branch is ahead of" &> /dev/null; echo "$?"`
        newfile=`echo -n "${status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?"`
        renamed=`echo -n "${status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?"`
        deleted=`echo -n "${status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?"`
        bits=''
        if [ "${renamed}" == "0" ]; then
                bits=">${bits}"
        fi
        if [ "${ahead}" == "0" ]; then
                bits="*${bits}"
        fi
        if [ "${newfile}" == "0" ]; then
                bits="+${bits}"
        fi
        if [ "${untracked}" == "0" ]; then
                bits="?${bits}"
        fi
        if [ "${deleted}" == "0" ]; then
                bits="x${bits}"
        fi
        if [ "${dirty}" == "0" ]; then
                bits="!${bits}"
        fi
        if [ ! "${bits}" == "" ]; then
                echo " ${bits}"
        else
                echo ""
        fi
}

# this line appends the git information to your existing prompt.
# so if your existing prompt is like
#
# [path_to_dir]$  
#
# then afterwards your prompt will look the same for non git folders
# but like this inside git folders:
#
# [path_to_dir]$ [{branch} {status}] $>
#
# e.g. when you are in your master branch and have added a new file that is not
# commited or added yet.
# ~/workspace$ [master +] $>

# \e[1;33m and \e[0m is color information
# \`parse_git_branch\` retrieves the information about the folder/repo

export PS1="$PS1 \e[1;33m\`parse_git_branch\` \\$> \e[0m"

# ==================== /GIT BASH EXTENSION ============================
