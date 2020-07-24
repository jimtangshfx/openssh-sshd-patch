# openssh-sshd-patch
    A shell script patching sshd to dump every command input/output generated by shell into log file
# background of this sshd patch
During my daily work,there is always some requirement that we need to track a remote ssh client's commands input/output,unfortunately, those communications are based on SSH encrypted connections and it's hard to debug it even with pcap capture of ssh traffic due to the encryption.

And even highest debug level of sshd won’t print out any command execution detail.

So I wrote this shell script which would hack into the binary code of sshd executable file on the server, replace 58 bytes binary codes of the sshd file by the new ones to force sshd print out every command input/output into the /var/log/auth.log file.

By that, one can easily check the auth.log and figure out whether an outside device has established SSH connection to server, what kind of commands has been executed and what's the result of command execution.

Below screenshot is an example of monitoring debug info in auth.log in real time after applying the binary patch, which prints out the debug info of a new incoming ssh connection (the new incoming ssh is on the right part of the screenshot).

![sample-output-of-patch-sshd](/images/patched-sshd-output.png)
# How the shell script works
The main idea is to replace some binary codes of sshd file by our own machine codes, to call error function to print out the buffer every time function "channel_handle_rfd" was called inside sshd.

In the below "if/else" conditional codes of function channel_handle_rfd, in most of the time, the value of (c->input_filter != NULL) would be false on ubuntu server, so we can safely assume the codes under "if (c->input_filter != NULL)" would not be executed, so we can replace them by our own codes.

>>>>>>>>>>>
if (c->input_filter != NULL) {

		if (c->input_filter(c, buf, len) == -1) {
		
			debug2("channel %d: filter stops", c->self);
			
			chan_read_failed(c);
		}
		
	} else if (c->datagram) {
	
		buffer_put_string(&c->input, buf, len);
		
	} else {
	
		buffer_append(&c->input, buf, len);
		
	}

>>>>>>>>>>
below are the main codes we used to replace the old ones in sshd with openssh version 7.2p2 on ubuntu server.

since the file size and memory address of different version of sshd executable files are different, the shell script
would check the version of sshd and replace it with different values.

currently, this shell scripts support sshd version 6.6p1 or 6.6.1p1 or 7.2p2 only.

>>>>>>>>>>
@42ec8:       49 89 c7                mov    r15,rax                                 #temporarily save the value in rax.

@42ecb:       48 8d 3d 88 2d 04 00    lea    rdi,[rip+0x42d8f]                       #the first parameter is string "JimDbg:Msg In/Out:(%.*s)" @ 0x85c5a  

@42ed2:       89 c6                   mov    esi,eax                                 #value in eas is the length of buffer.	

@42ed4:       48 89 e2                mov    rdx,rsp                                 #value in the rsp is the memory address of buffer.

@42ed7:       e8 04 a4 00 00          call   0x4d2e0 <error>                         #call error function to print out debug info.
	
@42edc:       90 90 90                                                               #NOP instruction code to do nothing, just to make file size unchanged.
	
@42edf:       4c 89 f8                mov    rax,r15                                 #restore rax

@42ee2:       e9 99 00 00 00          jmp    0x42f80                                 #jump to normal codes.
>>>>>>>>>>>
so the codes we write into sshd file using shell script would be:

/usr/bin/printf '\x49\x89\xc7\x48\x8d\x3d\x88\x2d\x04\x00\x89\xc6\x48\x89\xe2\xe8\x04\xa4\x00\x00\x90\x90\x90\x4c\x89\xf8\xe9\x99\x00\x00\x00' |/bin/dd of=/usr/sbin/sshd-temp bs=1 seek=274120 count=31 conv=notrunc 2>&1

also, we need to replace one string "channel %d: filter stops" in .rodata of sshd file at address 0x85c5a by new string "JimDbg:Msg In/Out:(%.*s)", which would be the first parameter when we call function error to print out buffer.

so below codes in script would be written into sshd by offset 0x85c5a.

/usr/bin/printf '\x4A\x69\x6D\x44\x62\x67\x3A\x4D\x73\x67\x20\x49\x6E\x2F\x4F\x75\x74\x3A\x28\x25\x2E\x2A\x73\x29\x00' |/bin/dd of=/usr/sbin/sshd-temp bs=1 seek=547930 count=25 conv=notrunc 2>&1
	
#how to use this script:

Simply put attached patch-sshd.sh onto the target server by ftp, or just create a new .sh file and copy the content of attached patch-sshd.sh file into that new created .sh file.

then run command "chmod 755 patch-sshd.sh" to make it executable.

Switch to root account (this script needs root privilege), then run "./patch-sshd.sh" to patch the /usr/sbin/sshd file. The script would restart sshd service automatically once done.

After that, you'll see debug log info printed into /var/log/auth.log file, and you could "tail -f /var/log/auth.log" to check out all the command input/output made by any new SSH connection in real time.

#One limitation of current sshd patch script:

The patched sshd process would print any output of ssh commands executions into /var/log/auth.log file, so in case you run "tail -f /var/log/auth.log" to monitor the output of auth.log in real time, the output of "tail" command would be printed into auth.log again, this would result in loop of auth.log generation&new log displayed to your terminal, so you may see many flooded debug info displayed when you run "tail -f /var/log/auth.log".
There are fours solutions for this limitation:

1. don't close your current ssh connection terminal window from which you run "./patch-sshd.sh", and use the same window to run "tail -f /var/log/auth.log" after patching sshd.This could avoid log loop and flooding as the current ssh connection was established based on non-patched sshd process (before you run patch), so this ssh connection would not print out any log into /var/log/auth.log. Therefor it won't cause log loop and flooding even if you "tail -f /var/log/auth.log" to monitor the auth.log in real time.
2. or open a new terminal window, use telnet to login to the server instead of ssh. By that, you could also run "tail -f /var/log/auth.log" without flooding logs into auth.log, as the telnet service is not patched at all and it won't print any debug log into auth.log.
3. or run "/usr/sbin/sshd.bak -p 777" to bring up the old sshd version and listens on port 777(change port number as you want), then establish a new ssh connection to port 777(instead of default port 22 which is  listend by patched sshd now), then run "tail -f /var/log/auth.log" from the new ssh windows with port 777. This could also avoid log flooding as tail command executed by such ssh connection is baed on old sshd which would not print out terminal display into auth.log, while the display of ssh           connection  with patched sshd port 22 would still be printed into  logs. 
4. or simply don't run "tail -f /var/log/auth.log" to monitor the debug info of ssh in real time, instead, wait until your test finished and log generated, then open the auth.log using vi to check the logs afterwards.
