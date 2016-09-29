# Docker image for PHP 7
Fork of official docker php image.  
Based on debian jessie

This fork was done to raise fd-size from 1024 to 50 000 which is more usable for any daemon :)

Includes : 

 - PHP : 7.0.11
 - ZeroMQ : 4.1.5 
 - Msgpack : 2.0.1
 - MongoDB : 1.1.8
 - Ev : 1.0.3
 
 
Vim and curl are also bundled for easy debugging

## Configuration 

Default folder is /code you should mount your php project here 
