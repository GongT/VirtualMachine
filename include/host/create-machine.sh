#!/usr/bin/env bash

function init_machine_base() {
	within_machine "$1"
	create_mdnf_run_args systemd bash
	screen_run "Create container: $CURRENT_MACHINE" "${__TEMP_DNF_RUN[@]}"


}