# czsip/fiji with additional xvfb support
# Author: Robert Kirmse
# Version: 0.1
# modified: Kota Miura

# Pull base CZSIP/Fiji.
FROM czsip/fiji_linux64_baseimage:1.2.8
#FROM czsip/fiji

#Fix from 
#RUN echo "deb [check-valid-until=no] http://cdn-fastly.deb.debian.org/debian jessie main" > /etc/apt/sources.list.d/jessie.list
#RUN echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list
#RUN sed -i '/deb http:\/\/\(deb\|httpredir\).debian.org\/debian jessie.* main/d' /etc/apt/sources.list
#RUN apt-get -o Acquire::Check-Valid-Until=false update

#get additional stuff
RUN apt-get update
RUN apt-get install -y apt-utils software-properties-common
RUN apt-get upgrade -y

 
# get Xvfb virtual X server and configure
RUN apt-get install -y xvfb x11vnc x11-xkb-utils xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic x11-apps
RUN apt-get install -y libxrender1 libxtst6 libxi6
                           
# Install additional Fiji Plugins
COPY ./CallLog.class /Fiji.app/plugins
COPY ./*.ijm /
COPY ./JSON_Read.js /
COPY ./start.sh /
COPY ./font.conf /etc/fonts/fonts.conf


VOLUME [ "/input", "/output", "/params" ]

# Setting ENV for Xvfb and Fiji
ENV DISPLAY :99
ENV PATH $PATH:/Fiji.app/

# Entrypoint for Fiji script has to be added below!
ENTRYPOINT ["sh","/start.sh"]
