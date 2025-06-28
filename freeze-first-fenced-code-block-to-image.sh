#!/usr/bin/env bash

## Find true directory this script resides in
__SOURCE__="${BASH_SOURCE[0]}"
while [[ -h "${__SOURCE__}" ]]; do
    __SOURCE__="$(find "${__SOURCE__}" -type l -ls | sed -n 's@^.* -> \(.*\)@\1@p')"
done
__NAME__="${__SOURCE__##*/}"
__DIR__="$(cd -P "$(dirname "${__SOURCE__}")" && pwd)"
__AUTHOR__='S0AndS0'
__DESCRIPTION__='Convert first fenced code block for given file into image(s) within output directory'

set -Ee

__usage__() {
	local _message=( "${@}" )

	cat <<EOF
${__DESCRIPTION__}
--input-file            --input <FILE>
	MarkDown file path

--output-directory      --output <DIRECTORY>
	Directory where images will be saved

--freeze-configuration  --freeze-config <FILE>
	Configuration file path for freeze CLI
	Default: ${XDG_CONFIG:-${HOME}/.config}/freeze/user.json

--language <LANGUAGE>
	Ignore/override/define language instead of attempting to auto-detect

--dry-run
	Print actions without executing commands

--help
	Print this message and exit

--no-convert
	Skip converting PNG image from freeze to other image formats

--verbose
	Print actions that will be taken

## Example

### Print this message and exit

${__NAME__} --help

### Create and convert image for an Erlang post

${__NAME__} --dry-run --verbose \\
  --input misc/_erlang/rebar3-umbrella-soup.md \\
  --output assets/images/erlang
EOF

	if (( ${#_message[@]} )); then
		printf >&2 '\n%s\n' "${_message[@]}"
		exit 1
	fi
	exit 0
}

while ((${#@})); do
	case "${1:?Undefined parameter}" in
		--input-file|--input)
			_input_file="${2:?Undefined value for --input-file}"
			shift 2;
		;;
		--output-directory|--output)
			_output_directory="${2:?Undefined value for --output-directory}"
			shift 2;
		;;
		--freeze-configuration|--freeze-config)
			_freeze_configuration="${2:?Undefined value for --freeze-configuration}"
			shift 2;
		;;
		--language)
			_language="${2:?Undefined value for --language}"
			shift 2;
		;;
		--dry-run)
			_dry_run=1
			shift 1;
		;;
		--help|-h)
			__usage__ ''
		;;
		--verbose)
			_verbose=1
			shift 1;
		;;
		*)
			__usage__ "Unrecognized parameter: ${1}"
		;;
	esac
done

if ! (( ${#_freeze_configuration} )); then
	_freeze_configuration__defaulted=1
	_freeze_configuration="${XDG_CONFIG:-${HOME}/.config}/freeze/user.json"
fi

if (( _verbose )); then
	printf >&2 'Parsed arguments\n'
	column >&2 --table --table-columns 'Parameter,Value' <<EOF
--input-file           |${_input_file}
--output-directory     |${_output_directory}
--freeze-configuration |${_freeze_configuration}
--language             |${_language}
--dry-run              |${_dry_run:-0}
--help                 |${_help:-0}
--verbose              |${_verbose:-0}
EOF
fi

if ! (( ${#_input_file} )); then
	__usage__ 'Missing parameter: --input-file'
fi

if ! (( ${#_output_directory} )); then
	__usage__ 'Missing parameter: --output-directory'
fi

if ! [[ -f "${_input_file}" ]]; then
	printf >&2 'File does not exist for: --input "%s"\n' "${_input_file}"
	exit 1
fi

_input_file__name="$(basename --suffix=".${_input_file##*.}" "${_input_file}")"
_output_directory="${_output_directory%/}/${_input_file__name}"
_output_file__base="${_output_directory}/first-code-block"

_first_code_block="$(
	awk '
		/```(\w)+$/{ flag = 1; }
		/```$/{ print; exit; }
		flag;
	' "${_input_file}"
)"
if ! (( ${#_first_code_block} )); then
	printf >&2 'No code blocks detected for: --input-file %s\n' "${_input_file}"
	exit 1
fi

if ! (( ${#_language} )); then
	_language="$(
		sed -E '1{
			s/^(\s*)(`)+(\w)/\3/g;
			q;
		}' <<<"${_first_code_block}"
	)"
	if (( _verbose )); then
		printf >&2 'Parsed language from first code block -> %s\n' "${_language}"
	fi
fi
_code_content="$(sed '1d;$d' <<<"${_first_code_block}")"

_code_content__height="$(wc -l <<<"${_code_content}")"

_code_content__width="$(
	awk '{
		_new_width = length($0);
		if (_new_width > _max_width) {
			_max_width = _new_width;
		}
	}
	END {
		print _max_width;
	}' <<<"${_code_content}"
)"

## Aspect ratio of 1.91:1 is recommended by CSS Tricks
if [[ -f "${_freeze_configuration}" ]]; then
	_font_size="$(jq -r '.font.size' "${_freeze_configuration}")"
else
	_font_size=14
fi

_awk_var_args=(
	-v _width="${_code_content__width}"
	-v _height="${_code_content__height}"
	-v _font_size="${_font_size}"
)

_padding_height="$(
	awk "${_awk_var_args[@]}" 'BEGIN {
			print int(((_width / 1.91) - _height) / 2) * _font_size;
		}'
)"

_padding_width="$(
	awk "${_awk_var_args[@]}" 'BEGIN {
		print int(((1.91 * _height) - _width) / 2) * _font_size;
	}'
)"

if { (( _verbose )) || (( _dry_run )) } && ! [[ -d "${_output_directory:?Undefined output directory}" ]]; then
	printf >&2 'mkdir -p "%s"\n' "${_output_directory}"
fi
if ! (( _dry_run )) && ! [[ -d "${_output_directory:?Undefined output directory}" ]]; then
	mkdir -p "${_output_directory}"
fi

_freeze_args=()
if ((${#_language})); then
	_freeze_args+=( --language "${_language}" )
fi

_freeze_args+=( --output "${_output_file__base}.png" )

if [[ -f "${_freeze_configuration}" ]]; then
	_freeze_args+=( --config "${_freeze_configuration}" )
fi

## Aspect ratio of 1.91:1 is recommended by CSS Tricks
_freeze_args+=(
	--width 1200
	--height 630
)

if [[ "${_padding_height}" -gt 0 ]]; then
	_freeze_args+=( --padding "${_padding_height},14" )
elif [[ "${_padding_width}" -gt 0 ]]; then
	_freeze_args+=( --padding "14,${_padding_width}" )
fi

if (( _verbose )) || (( _dry_run )); then
	cat >&2 <<EOL
freeze ${_freeze_args[@]} <<EOF
${_code_content}
EOF
EOL
fi

if ! (( _dry_run )); then
	freeze "${_freeze_args[@]}" <<EOF
${_code_content}
EOF
fi

# vim: noexpandtab
