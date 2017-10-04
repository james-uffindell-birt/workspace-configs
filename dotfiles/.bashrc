

        RED="\[\033[0;31m\]"
     YELLOW="\[\033[0;33m\]"
      GREEN="\[\033[0;32m\]"
       BLUE="\[\033[0;34m\]"
  LIGHT_RED="\[\033[1;31m\]"
LIGHT_GREEN="\[\033[1;32m\]"
LIGHT_BLUE="\[\033[1;34m\]"
      WHITE="\[\033[1;37m\]"
 LIGHT_GRAY="\[\033[0;37m\]"
 COLOR_NONE="\[\e[0m\]"
MID_PURPLE="\[\033[38;5;99m\]"
MID_LILAC="\[\033[38;5;147m\]"
MID_MARIGOLD="\[\033[38;5;221m\]"
MID_AQUA="\[\033[38;5;122m\]"
MID_ORANGE="\[\033[38;5;214m\]"
MID_RED="\[\033[38;5;196m\]"
MID_BLUE="\[\033[38;5;39m\]"
MID_GREEN="\[\033[38;5;148m\]"
MID_YELLOW="\[\033[38;5;227m\]"
MOSS_GREEN="\[\033[38;5;107m\]"
PALE_BLUE="\[\033[38;5;117m\]"

ACTUAL_BACKGROUND="\[\033[48;2;13;0;13m\]"
LILAC_BACKGROUND="\[\033[48;2;175;175;255m\]"
BG_AS_FOREGROUND="\[\033[38;2;13;0;13m\]"

 
function parse_git_branch {

  git rev-parse --git-dir &> /dev/null
  git_status="$(git status 2> /dev/null)"
  working_file_count="$(git status -s 2> /dev/null | egrep '^.[MARCD]' | wc -l)"
  indexed_file_count="$(git status -s 2> /dev/null | egrep '^[MARCD]' | wc -l)"
  untracked_file_count="$(git status -s 2> /dev/null | egrep '^\?\?' | wc -l)"
  
  # various sorts of output to look for
  branch_pattern="^On branch ([^${IFS}]*)"
  detached_pattern="^HEAD detached at ([^${IFS}]*)"
  detached_pattern_2="^HEAD detached from ([^${IFS}]*)"
  remote_match_pattern="Your branch is up-to-date with '([^${IFS}]*)'"
  remote_ahead_pattern="Your branch is ahead of '([^${IFS}]*)' by ([^${IFS}]*) commit"
  remote_behind_pattern="Your branch is behind '([^${IFS}]*)' by ([^${IFS}]*) commit"
  diverge_pattern="Your branch and '([^${IFS}]*)' have diverged"
  rebase_pattern="rebasing branch '([^${IFS}]*)' on '([^${IFS}]*)'"
  bisect_pattern="currently bisecting, started from branch '([^${IFS}]*)'"
  cherry_pattern="currently cherry-picking commit ([^{IFS}]*)\\."
  zero_pattern="^0$"
  digits_pattern="^[[:digit:]]{1,2}$"
  
  #STEP 1: check the status of our working dir and index
  if [[ ${working_file_count} =~ ${zero_pattern} ]]; then
    working_state="${MID_GREEN}✓    "
  elif [[ ${working_file_count} =~ ${digits_pattern} ]]; then
    working_state="${MID_GREEN}☢ $(printf '%-2s' ${working_file_count}) "
  else
    working_state="${MID_GREEN}☢ ∞  "
  fi
  
  if [[ ${indexed_file_count} =~ ${zero_pattern} ]]; then
    index_state="${MID_PURPLE}✓    "
  elif [[ ${indexed_file_count} =~ ${digits_pattern} ]]; then
    index_state="${MID_PURPLE}❄ $(printf '%-2s' ${indexed_file_count}) "
  else
    index_state="${MID_PURPLE}❄ ∞  "
  fi
  
  if [[ ${untracked_file_count} =~ ${zero_pattern} ]]; then
    untracked_state="${PALE_BLUE}✓    "
  elif [[ ${untracked_file_count} =~ ${digits_pattern} ]]; then
    untracked_state="${PALE_BLUE}❄ $(printf '%-2s' ${untracked_file_count}) "
  else
    untracked_state="${PALE_BLUE}❄ ∞  "
  fi
  
  state="${index_state}${working_state}${untracked_state}"
  
  #STEP 2: check the status of our branch compared to its tracking branch (if any)
  if [[ ${git_status} =~ ${remote_ahead_pattern} ]]; then
    num_commits=${BASH_REMATCH[2]}
    if [[ ${num_commits} =~ ${digits_pattern} ]]; then
      remote="${MOSS_GREEN}↑ $(printf '%-2s' ${num_commits}) "
    else
      remote="${MOSS_GREEN}↑ ∞  "
    fi
  elif [[ ${get_status} =~ ${remote_behind_pattern} ]]; then
    num_commits=${BASH_REMATCH[2]}
    if [[ ${num_commits} =~ ${digits_pattern} ]]; then
      remote="${MOSS_GREEN}↓ $(printf '%-2s' ${num_commits}) "
    else
      remote="${MOSS_GREEN}↓ ∞  "
    fi
  elif [[ ${git_status} =~ ${diverge_pattern} ]]; then
    remote="${MOSS_GREEN}↕    "
  else
    remote="${MOSS_GREEN}✓    "
  fi
  
  #STEP 3: check what branch we're currently on
  #check more complicated situations first: rebase, bisecting, cherry-picking (merging?)
  if [[ ${git_status} =~ ${rebase_pattern} ]]; then
    src_branch=${BASH_REMATCH[1]}
    tgt_branch=${BASH_REMATCH[2]}
    
    if [[ ${git_status} =~ "interactive rebase in progress" ]]; then
      done_pattern='done \(([[:digit:]]*) command'
      todo_pattern='to do \(([[:digit:]]*) remaining command'
      num_done=0
      num_todo=0
      if [[ ${git_status} =~ ${done_pattern} ]]; then
        num_done=${BASH_REMATCH[1]}
      fi
    
      if [[ ${git_status} =~ ${todo_pattern} ]]; then
        num_todo=${BASH_REMATCH[1]}
      fi
    
      if [[ ${git_status} =~ "all conflicts fixed" ]]; then
        echo " ${MID_GREEN}(☠ ${src_branch} → ${tgt_branch}; ${num_done} applied; ${num_todo} remaining ☠) ${remote}${state}"
      elif [[ ${git_status} =~ "currently editing" ]]; then
        echo " ${MID_YELLOW}(☠ ${src_branch} → ${tgt_branch}; ${num_done} applied; ${num_todo} remaining ☠) ${remote}${state}"
      elif [[ ${git_status} =~ "currently splitting" ]]; then
        echo " ${MID_ORANGE}(☠ ${src_branch} → ${tgt_branch}; ${num_done} applied; ${num_todo} remaining ☠) ${remote}${state}"
      else
        echo " ${MID_RED}(☠ ${src_branch} → ${tgt_branch}; ${num_done} applied; ${num_todo} remaining ☠) ${remote}${state}"
      fi
      
    else
      if [[ ${git_status} =~ "all conflicts fixed" ]]; then
        echo " ${MID_GREEN}(☠ ${src_branch} → ${tgt_branch} ☠) ${remote}${state}"
      else
        echo " ${MID_RED}(☠ ${src_branch} → ${tgt_branch} ☠) ${remote}${state}"
      fi
    fi
  elif [[ ${git_status} =~ ${bisect_pattern} ]]; then
    start_branch=${BASH_REMATCH[1]}
    
    git_bisect_good="$(git bisect log | grep 'good:' | sed -e 's/\# good: \[//g' -e 's/\].*$//g' | tail -1 | xargs git rev-parse --short 2> /dev/null)"
    if [[ "x${git_bisect_good}" == "x" ]]; then
      git_bisect_good='???'
    fi
    git_bisect_bad="$(git bisect log | grep 'bad:' | sed -e 's/\# bad: \[//g' -e 's/\].*$//g' | tail -1 | xargs git rev-parse --short 2> /dev/null)"
        if [[ "x${git_bisect_bad}" == "x" ]]; then
      git_bisect_bad='???'
    fi
    if [[ ${git_status} =~ ${detached_pattern} ]]; then
      location=${BASH_REMATCH[1]}
    else
      location='???'
    fi
    echo " ${MID_MARIGOLD}(${MID_GREEN}${git_bisect_good} ${MID_MARIGOLD}↔ ${MID_ORANGE}${location} ${MID_MARIGOLD}↔ ${MID_RED}${git_bisect_bad} ${MID_MARIGOLD}(${start_branch})) ${remote}${state}"

  #cherry-picking
  elif [[ ${git_status} =~ ${cherry_pattern} ]]; then
    commit=${BASH_REMATCH[1]}
    
    if [[ ${git_status} =~ ${branch_pattern} ]]; then
      branch=${BASH_REMATCH[1]}
      if [[ ${git_status} =~ ${remote_match_pattern} || ${git_status} =~ ${remote_ahead_pattern} || ${git_status} =~ ${remote_behind_pattern} || ${git_status} =~ ${diverge_pattern} ]]; then
        remote_branch=" ${MOSS_GREEN}[${BASH_REMATCH[1]}]"
      fi
    
      if [[ ${git_status} =~ "You have unmerged paths" || ${git_status} =~ "fix conflicts" ]]; then
        echo " ${MID_RED}(🍒 ${commit} → ${branch}${remote_branch}${MID_RED} 🍒) ${remote}${state}"
      else
        echo " ${MID_MARIGOLD}(🍒 ${commit} → ${branch}${remote_branch}${MID_MARIGOLD} 🍒) ${remote}${state}"
      fi
    elif [[ ${git_status} =~ ${detached_pattern} ]]; then
      location=${BASH_REMATCH[1]}
    
      if [[ ${git_status} =~ "You have unmerged paths" || ${git_status} =~ "fix conflicts" ]]; then
        echo " ${MID_RED}(🍒 ${commit} → ${location} 🍒) ${remote}${state}"
      else
        echo " ${MID_ORANGE}(🍒 ${commit} → ${location} 🍒) ${remote}${state}"
      fi
    fi

  #no special state
  elif [[ ${git_status} =~ ${branch_pattern} ]]; then
    branch=${BASH_REMATCH[1]}
    if [[ ${git_status} =~ ${remote_match_pattern} || ${git_status} =~ ${remote_ahead_pattern} || ${git_status} =~ ${remote_behind_pattern} ]]; then
        remote_branch=" ${MOSS_GREEN}[${BASH_REMATCH[1]}]"
    fi
    
    if [[ ${git_status} =~ "You have unmerged paths" ]]; then
      echo " ${MID_RED}(${branch}${remote_branch}${MID_RED}) ${remote}${state}"
    else
      echo " ${MID_MARIGOLD}(${branch}${remote_branch}${MID_MARIGOLD}) ${remote}${state}"
    fi
  elif [[ ${git_status} =~ ${detached_pattern} ]]; then
    location=${BASH_REMATCH[1]}
    
    if [[ ${git_status} =~ "You have unmerged paths" ]]; then
      echo " ${MID_RED}(✂ ${location} ✂) ${remote}${state}"
    else
      echo " ${MID_ORANGE}(✂ ${location} ✂) ${remote}${state}"
    fi
  elif [[ ${git_status} =~ ${detached_pattern_2} ]]; then
    location="$(git rev-parse --short HEAD 2> /dev/null)"
    if [[ ${git_status} =~ "You have unmerged paths" ]]; then
      echo " ${MID_RED}(✂ ${location} ✂) ${remote}${state}"
    else
      echo " ${MID_ORANGE}(✂ ${location} ✂) ${remote}${state}"
    fi
  elif [[ ${git_status} =~ "Not currently on any branch" ]]; then
    echo " ${MID_ORANGE}(✂ (no branch) ✂) ${remote}${state}"
  fi
}

function prompt_func() {
    previous_return_value=$?;
    if [ "$TERM" != "linux" -a -z "$EMACS" ]
    then
        TITLEBAR="\[\e]2;\u@\h:\w\a\]"
    else
        TITLEBAR=""
    fi
    prompt="${TITLEBAR}${MID_PURPLE}[${MID_BLUE}\u@\h ${BG_AS_FOREGROUND}${LILAC_BACKGROUND}\w${COLOR_NONE}$(parse_git_branch)${MID_PURPLE}]${COLOR_NONE}"
    if test $previous_return_value -eq 0
    then
        PS1="${prompt}${MID_AQUA}\\\$${COLOR_NONE} "
    else
        PS1="${prompt}${MID_AQUA}\\\$${COLOR_NONE} "
    fi
}

PROMPT_COMMAND=prompt_func

alias cdr='cd "$(git rev-parse --show-cdup)"'