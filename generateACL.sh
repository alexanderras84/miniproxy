#!/bin/bash
CLIENTS=()
export DYNDNS_CRON_ENABLED=false

function read_acl () {
  for i in "${client_list[@]}"
  do
    # Time-bound ipcalc to 5 seconds
    timeout 5s /usr/bin/ipcalc -cs "$i"
    retVal=$?
    if [ $retVal -eq 0 ]; then
      CLIENTS+=( "${i}" )
    else
      # Time-bound the entire DNS resolution + jq pipeline
      RESOLVE_RESULT=$(timeout 5s bash -c "/usr/bin/dog --json '${i}' | jq -r '.responses[].answers | map(select(.type == \"A\")) | first | .address'")
      retVal=$?
      if [ $retVal -eq 0 ] && [ -n "$RESOLVE_RESULT" ]; then
        export DYNDNS_CRON_ENABLED=true
        CLIENTS+=( "${RESOLVE_RESULT}" )
      else
        echo "[ERROR] Could not resolve '${i}' (timeout or failure) => Skipping"
      fi
    fi
  done

  # Ensure 127.0.0.1 is present if dynamic DNS clients were resolved
  (echo "${client_list[@]}" | grep -q '127.0.0.1')
  localipCheck=$?
  if [[ "$localipCheck" -ne 0 ]] && [[ "$DYNDNS_CRON_ENABLED" = true ]]; then
    echo "[INFO] Adding '127.0.0.1' to allowed clients to prevent reload issues"
    CLIENTS+=( "127.0.0.1" )
  fi
}

# Determine client list source
if [ -n "${ALLOWED_CLIENTS_FILE}" ];
then
  if [ -f "${ALLOWED_CLIENTS_FILE}" ];
  then
    mapfile -t client_list < "$ALLOWED_CLIENTS_FILE"
  else
    echo "[ERROR] ALLOWED_CLIENTS_FILE is set but file does not exist or is not accessible!"
    exit 1
  fi
else
  IFS=', ' read -ra client_list <<< "$ALLOWED_CLIENTS"
fi

# Run ACL generation
read_acl

# Generate NGINX ACL files
printf '%s\n' "${CLIENTS[@]}" > /etc/nginx/allowedClients.acl

if [ -f "/etc/nginx/allowedClients.acl" ];
then
  echo "" > /etc/nginx/allowedClients.conf
  while read -r line
  do
    echo "allow $line;" >> /etc/nginx/allowedClients.conf
  done < "/etc/nginx/allowedClients.acl"
  echo "deny  all;" >> /etc/nginx/allowedClients.conf
else
  touch /etc/nginx/allowedClients.conf
fi
