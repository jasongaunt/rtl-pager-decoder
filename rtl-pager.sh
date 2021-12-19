#!/bin/bash

# Script to tune an RTL_TCP receiver to POGSAG / FLEX pager frequencies and output messages
# WARNING: You must hold a valid ham operators license to use this script and also obey local laws
#
# Output example:
# 2021-05-05 09:43:03: POCSAG1200: Address:  1234567  Function: 3  Alpha:  This is my test message here

# Do not edit below this point unless you know what you're doing
source ./config.sh

# Define our temporary sock file locations
IQ_FEED_SOCKET="/tmp/rtl-pager-iq_feed.$$.sock"
MESSAGES_SOCKET="/tmp/rtl-pager-messages.$$.sock"

# Trap ctrl+c so we can clean up background tasks
trap "clean_exit" INT TERM ERR EXIT
clean_exit() {
	pkill -P $$
}

# Calculate center frequency between all frequencies
RTL_LOWEST_FREQUENCY=999999999999
RTL_HIGHEST_FREQUENCY=0
RTL_AVERAGE_FREQUENCY=0
for frequency in "${RTL_TCP_FREQUENCY_LIST[@]}"; do
	RTL_AVERAGE_FREQUENCY=$(expr "${RTL_AVERAGE_FREQUENCY}" + "${frequency}")
	if [[ "${frequency}" -gt "${RTL_HIGHEST_FREQUENCY}" ]]; then RTL_HIGHEST_FREQUENCY="${frequency}"; fi
	if [[ "${frequency}" -lt "${RTL_LOWEST_FREQUENCY}" ]];  then RTL_LOWEST_FREQUENCY="${frequency}"; fi
done
RTL_TCP_CENTER_FREQUENCY_HZ=$(expr "${RTL_AVERAGE_FREQUENCY}" / "${#RTL_TCP_FREQUENCY_LIST[@]}")
echo "Calculated center frequency is ${RTL_TCP_CENTER_FREQUENCY_HZ} Hz"

# Make sure we can actually tune this amount
RTL_REQUIRED_MINIMUM_SAMPLE_RATE=$(expr "${RTL_HIGHEST_FREQUENCY}" - "${RTL_LOWEST_FREQUENCY}"; true)
if [[ "${RTL_REQUIRED_MINIMUM_SAMPLE_RATE}" -gt "${RTL_TCP_SAMPLE_RATE}" ]]; then
	echo "Unable to tune to the specified frequencies, required minimum sample rate ${RTL_REQUIRED_MINIMUM_SAMPLE_RATE} exceeds specified sample rate ${RTL_TCP_SAMPLE_RATE}"
	exit 1
fi

# Start our connection to RTL_TCP
echo -n "Starting socket server..."
socat UNIX-LISTEN:"${IQ_FEED_SOCKET}",fork TCP:"${RTL_TCP_HOST}":"${RTL_TCP_PORT}" &
while [[ ! -S "${IQ_FEED_SOCKET}" ]]; do echo -n "."; sleep 0.1; done
echo " done"

# Send our tune command
echo -n "Tuning RTL..."
perl -e "print pack('C', '1') . pack('N', $RTL_TCP_CENTER_FREQUENCY_HZ) . pack('C', '2') . pack('N', $RTL_TCP_SAMPLE_RATE) . pack('C', '3') . pack('C', $RTL_TCP_MANUAL_GAIN_MODE) . pack('C', '4') . pack('C', $RTL_TCP_GAIN_LEVEL)" | \
socat UNIX-CONNECT:"${IQ_FEED_SOCKET}" -
echo " done"

# Start outputting messages background task
socat "UNIX-LISTEN:${MESSAGES_SOCKET},fork" - | \
sed -e 's/^\([^ ]\+ \+[^ ]\+\) \+\([^ ]\+\) \+\([^ ]\+ \+[^ ]\+\) \+\([^ ]\+ \+[^ ]\+\) \+\([^ ]\+\) \+\(.\+\)/\x1b[1;31m\1\t\x1b[1;32m\2\t\x1b[1;33m\3\t\x1b[1;34m\4\t\x1b[1;35m\5\t\x1b[1;36m\6\t\x1b[00m/g' &

# Start processing messages background tasks
for frequency in "${RTL_TCP_FREQUENCY_LIST[@]}"; do
	frequency_shift=$(perl -e "print ((${RTL_TCP_CENTER_FREQUENCY_HZ} - ${frequency}) / ${RTL_TCP_SAMPLE_RATE})")
	socat "UNIX-CONNECT:${IQ_FEED_SOCKET}" - | \
	csdr convert_u8_f 2>/dev/null | \
	csdr shift_addition_cc "${frequency_shift}" 2>/dev/null | \
	csdr fir_decimate_cc 50 0.005 HAMMING 2>/dev/null | \
	csdr fractional_decimator_cc 1.857596371882086 2>/dev/null | \
	csdr fmdemod_quadri_cf 2>/dev/null | \
	csdr limit_ff 2>/dev/null | \
	csdr convert_f_s16 2>/dev/null | \
	multimon-ng -t raw -a POCSAG512 -a POCSAG1200 -a POCSAG2400 -a FLEX -q -p -u -b 0 --timestamp - | \
	socat "UNIX-CONNECT:${MESSAGES_SOCKET}" - &
done

# Wait here for background processes to end
wait
