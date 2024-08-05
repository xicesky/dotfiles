#!/bin/bash

# Gerenate a single line of fake name
single_line() {
    declare full_name first_name
    external_id="$(uuidgen)"
    full_name="$(rig | head -n 1)"
    first_name="$(echo "$full_name" | awk '{print $1}')"
    last_name="$(echo "$full_name" | awk '{print $2}')"
    echo "(nextval('mx_contact_seq_value'), '${external_id}', 1, '{\"-\":\"${first_name}\"}', '{\"-\":\"${last_name}\"}', 'BACKEND', 0, 'GENERATOR', now(), 'UTC', now(), 'UTC'),"
}

main() {
    declare i count=10
    while [[ $# -gt 0 ]] ; do
        arg="$1"; shift
        case "$arg" in
            -*)
                { echo "Unknown flag: $arg"; usage; } 1>&2
                return 1
                ;;
            *)
                count="$arg"
                break
                ;;
        esac
    done

    echo "SET search_path TO sdm;"
    echo "INSERT INTO mx_contact"
    echo "(id, cot_external_id, cot_ten_id, cot_first_name, cot_last_name, cot_owner_system, version, creator, time_updated, time_updated_tz, time_stored, time_stored_tz)"
    echo "VALUES"
    {
        for ((i=0; i<count; i++)); do
            single_line
        done
    } | sed '$ s/.$/;/'
}

main "$@"
