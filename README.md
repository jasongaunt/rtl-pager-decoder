# RTL Pager Decoder

Script to tune an RTL_TCP receiver to one or more specified frequencies and decode any POGSAG / FLEX pager messages broadcast on those frequencies.

# Disclaimer

This script was built and tested in a controlled environment on license-free frequencies and within legal requirements.

To use this script on anything other than license-free bands you **must** hold a valid ham operator license and obey local laws.

It is **illegal** to republish (either *in part* or *in whole*) any private messages you have decoded. *Do **NOT** do it!*

This script is provided for educational-use only, without warranty or support, *please use it responsibly!*

# Requirements

This script depends upon the following:

* [Bash](https://www.gnu.org/software/bash/) (tested on 5.x, should work on 4.x, below that [*here be dragons*](https://en.wikipedia.org/wiki/Here_be_dragons))
* [Perl](https://www.perl.org/get.html) / [Sed](https://www.gnu.org/software/sed/manual/sed.html) / [Expr](https://linux.die.net/man/1/expr) (included in most Linux distributions)
* [RTL_TCP](https://osmocom.org/projects/rtl-sdr/wiki/Rtl-sdr)
* [Socat](https://linux.die.net/man/1/socat)
* [CSDR](https://github.com/ha7ilm/csdr)
* [multimon-ng](https://github.com/EliasOenal/multimon-ng)
* An RTL_TCP compatible receiver

# Development environment

* Raspberry Pi Zero 2 W running Raspbian OS (as of November 2021)
* Generic RTL SDR receiver (RTL2832U)
* Bash, Perl and Sed all came by default with Raspbian OS
* Packages were either installed using `apt` or built from source
* Sub-0.5 watt transmitter on the license-free PMR 446 band

# Setup

* Make sure you've got the above requirements installed
* Make sure you have RTL_TCP running
* Copy `config.sh.template` to `config.sh`

# Configuration

Open `config.sh` in your favourite text editor, within the configuration file you'll see the following;

```shell
# List of frequencies to listen to, they MUST all fit within RTL_TCP_SAMPLE_RATE
RTL_TCP_FREQUENCY_LIST=(
        446006250 # POCSAG
        446093750 # FLEX
)
```

Add your desired monitoring frequencies in the above format, each entry must be specified in Hz.

The `# POCSAG` and `# FLEX` parts are comments. These are optional, but it's good practice to document.

**Note:** The more frequencies you add, the more CPU overhead required to decode them.

# Usage

Run the script with `./rtl-pager.sh`, it will then perform the following:

The script will first calculate the center point of the configured frequencies and verify there is enough bandwidth within `RTL_TCP_SAMPLE_RATE` to receive them all.

If it cannot find enough bandwidth to cover all frequencies the script will error and explain why it cannot proceed.

Once it has verified it can tune them, the script will then connect to RTL_TCP and set the center frequency.

It will then fork subprocesses and start decoding messages sent to each of the individual frequencies above and output received pager messages to the terminal.

Here is an example of the output:

```
Calculated center frequency is 446050000 Hz
Starting socket server.... done
Tuning RTL... done

2021-05-05 09:43:03: POCSAG1200: Address:  1234567  Function: 3  Alpha:  This is my test message here
```

To stop the script, simply press `Ctrl+c` (or send `sigterm`) and it will clean up all subprocesses and exit.

# License

MIT License

Copyright (c) 2021 Jason Gaunt

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
