#!/bin/bash
user='starcor'

hash smbpasswd &>/dev/null || {
    echo "has not smbpasswd.exit"
    exit
}

hash expect &>/dev/null || {
    pacman -Sy --noconfirm expect
}

expect <<EOF
    set send_slow {1 .1}
	proc send {ignore arg} {
		sleep .1
		exp_send -s -- \$arg
	}
	set timeout $EXPECT_TIMEOUT

    spawn smbpasswd -a $user
    expect {
        -exact "*password:" { send -- "123qwe!\n"; exp_continue }
    }
EOF

 pacman -Rc --noconfirm expect