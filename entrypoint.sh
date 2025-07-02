#!/usr/bin/env bash

## Find true directory this script resides in
__SOURCE__="${BASH_SOURCE[0]}"
while [[ -h "${__SOURCE__}" ]]; do
	__SOURCE__="$(find "${__SOURCE__}" -type l -ls | sed -n 's@^.* -> \(.*\)@\1@p')"
done
__NAME__="${__SOURCE__##*/}"
__DIR__="$(cd -P "$(dirname "${__SOURCE__}")" && pwd)"
__AUTHOR__='S0AndS0'
__DESCRIPTION__='GitHub Action entry point to find files and call Freeze wrapper script'

##
# See https://github.com/bash-utilities/failure for updates of following function
#
# Bash Trap Failure, a submodule for other Bash scripts tracked by Git
# Copyright (C) 2023  S0AndS0
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation; version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
## Outputs Front-Mater formatted failures for functions not returning 0
## Use the following line after sourcing this file to set failure trap
##    trap 'failure "LINENO" "BASH_LINENO" "${?}"' ERR
failure(){
	local -n _lineno="${1:-LINENO}"
	local -n _bash_lineno="${2:-BASH_LINENO}"
	local _code="${3:-0}"

	## Workaround for read EOF combo tripping traps
	if ! ((_code)); then
		return "${_code}"
	fi

	local -a _output_array=()
	_output_array+=(
		'---'
		"lines_history: [${_lineno} ${_bash_lineno[*]}]"
		"function_trace: [${FUNCNAME[*]}]"
		"exit_code: ${_code}"
	)

	if [[ "${#BASH_SOURCE[@]}" -gt '1' ]]; then
		_output_array+=('source_trace:')
		for _item in "${BASH_SOURCE[@]}"; do
			_output_array+=("  - ${_item}")
		done
	else
		_output_array+=("source_trace: [${BASH_SOURCE[*]}]")
	fi

	_output_array+=('---')
	printf '%s\n' "${_output_array[@]}" >&2
	exit "${_code}"
}
trap 'failure "LINENO" "BASH_LINENO" "${?}"' ERR
set -Ee -o functrace


VERBOSE="${VERBOSE:-${INPUT_VERBOSE:-0}}"

_source_directory="${INPUT_SOURCE_DIRECTORY:?Undefined source directory}"
_find_regex="${INPUT_FIND_REGEX:?Undefined find -regex value}"
_find_regextype="${INPUT_FIND_REGEXTYPE:?Undefined find -regextype value}"

_sed_args="${INPUT_SED_ARGS}"
_sed_expression="${INPUT_SED_EXPRESSION}"

_clobber="${INPUT_CLOBBER:-0}"
_freeze_config="${INPUT_FREEZE_CONFIG}"

_found=()
_wrote=()
_failed=()

_command_find=(find "${_source_directory}" -type f)
if (( ${#_find_regex} )); then
	_command_find+=(-regex "${_find_regex}")
fi
if (( ${#_find_regextype} )); then
	_command_find+=(-regextype "${_find_regextype}")
fi
_command_find+=(-print0)

if (( VERBOSE )); then
	column >&2 --table --separator '|' --table-columns 'Name,Value' <<EOF
_find_regex       |${_find_regex}
_find_regextype   |${_find_regextype}
_freeze_config    |${_freeze_config}
_source_directory |${_source_directory}
_command_find     |${_command_find[*]}
EOF
fi

_command_script_base=( "${__DIR__}/freeze-first-fenced-code-block-to-image.sh" )
if (( VERBOSE )); then
	_command_script_base+=( --verbose )
fi
if (( ${#_freeze_config} )); then
	_command_script_base+=( --freeze-config "${_freeze_config}" )
fi

if (( ${#_sed_expression} )); then
	_command_sed=( sed )
	if (( ${#_sed_args} )); then
		# shellcheck disable=SC2206
		_command_sed+=( ${_sed_args} )
	fi
	_command_sed+=( "${_sed_expression}" )
fi

while read -rd '' _source_path; do
	_found+=( "${_source_path}" )

	_source_dirname="$(dirname "${_source_path}")"
	_source_basename="$(basename "${_source_path}")"
	_source_name="${_source_basename%.*}"

	_output_directory=""
	if (( ${#_sed_expression} )); then
		_output_directory+="$("${_command_sed[@]}" <<<"${_source_dirname}")"
	else
		_output_directory+="${_source_dirname}"
	fi

	_output_path="${_output_directory}/${_source_name}/first-code-block.png"
	if [[ -f "${_output_path}" ]] && ! ((_clobber)); then
		if (( VERBOSE )); then
			printf >&2 'Skipped preexisting -> %s\n' "${_output_path}"
		fi
		continue
	fi

	_command_script=(
		"${_command_script_base[@]}"
		--input "${_source_path}"
		--output-directory "${_output_directory}"
	)

	if (( VERBOSE )); then
		printf >&2 '_command_script ...\n'
		printf >&2 '\t%s\n' "${_command_script[@]}"
	fi

	if "${_command_script[@]}"; then
		_wrote+=("${_output_directory}")
		chmod go+r "${_output_path}"
	else
		_failed+=("${_output_directory}")
	fi
done < <("${_command_find[@]}")

if (( ${#_found[@]} )); then
	tee -a 1>/dev/null "${GITHUB_OUTPUT:?Undefined GitHub Output environment variable}" <<EOL
found<<EOF
$(printf '%s\n' "${_found[@]}")
EOF
EOL
fi

if (( ${#_wrote[@]} )); then
	tee -a 1>/dev/null "${GITHUB_OUTPUT:?Undefined GitHub Output environment variable}" <<EOL
wrote<<EOF
$(printf '%s\n' "${_wrote[@]}")
EOF
EOL
fi

if (( ${#_failed[@]} )); then
	tee -a 1>/dev/null "${GITHUB_OUTPUT:?Undefined GitHub Output environment variable}" <<EOL
failed<<EOF
$(printf '%s\n' "${_failed[@]}")
EOF
EOL
fi

# vim: noexpandtab
