# beaglebone

TODO make install transfer binaries remotely:
https://stackoverflow.com/questions/8970790/cmake-make-install-to-remote-machine
install (CODE "execute_process(COMMAND scp -r -i /home/user/.ssh/id_rsa ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/. user@remote:/path/to/copy/)")
install(CODE "execute_process(COMMAND /usr/bin/rsync -avh ${INSTALL_DIR} user@remote:/home/user/)")

