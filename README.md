# supercert

Generating TLS certificates sucks. That's why I made the supercert script. It's a bash script that does everything for you. You can toss in some simple-as-fuck files to set its configuration (none of that [openssl.cnf](http://web.mit.edu/crypto/openssl.cnf) bullshit), or you can not, and it'll just generate some simple-ass certs.

supercert can generate a new CA or it can use an existing one. It can also add a SAN to your certs. Here's how:

## Use existing CA

just get those got damn CA files (**ca.crt** and **ca.key** or **ca.pem** and **ca-key.pem** or whatever the fuck you have) and include them as arguments to the script. Like this:

`./supercert.sh /path/to/ca.crt /path/to/ca.key`

## Include SAN

just make a **san.csv** in the directory with the script and it'll add that shit right in -- no arguments necessary. I included a sample so that you can see the syntax: CSV, no commas, SAN numberless format -- very simple.

## Limitations
###### You're probably thinking "fuck me this is great!" and you are right. However, as great as it is, it does have some limitations.
1. These certs are self-signed -- this should only be used to generate certs for testing.
2. The script generates the certs in whatever directory you run the script in. The actual cert files are under the easyrsa directory but the script drops some symlinks in there so you don't have to go digging around for the files (however, I don't link ca.key but that's in easy-rsa-master/easyrsa3/pki/private/ if you need it, which you will if you want to generate multiple certs with the same CA)
3. You gotta change the file permissions of the certs to use them because I don't know what the fuck you're gonna use 'em for. They default to `-rw-------`. `chmod 640 <cert>` is the preferred way to set these bad bois. Also, if you're a dingus and your application still can't use these certs, it is probably because you didn't set the owner/group. So remember to do this: `chown <svc_account>:<svc_account_group> <cert files>`. For example: `chown etcd:etcd ca.* myserver.*`
4. This script uses your hostname to generate the name of the cert. If you don't have a special DNS name, then make one for yourself by using the hostname command and adding it in `/etc/hosts`. If you don't like that then go ahead and change the script bruh. At the top, you can change the HOSTNAME variable to whatever you like.
5. You gotta make the shit executable because file permissions don't persist on github: `chmod +x supercert.sh`
