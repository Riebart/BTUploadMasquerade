# BTUploadMasquerade
A little bit of Python that can sit inline between a BitTorrent client and tracker that will masquerade actual uploaded amount

## Background

There's a bunch of tools that do this (RatioMaster, RatioGhost, GreedyTorrent), but they suffer from issues related to HTTPS, and other problems (I couldn't get RatioGhost to work with qBittorrent, due to complaints about SSRF mitigations).

## Architecture

- For each tracker domain (e.g. tracker.example.com, or tracker2.example.com:4430 if it runs on a non standard port), run one of those scripts listening on its own port.
- Add a torrent to your client, but don't start it.
  - If your goal is to pretend to seed a torrent, pick one with lots of leechers, and only select the one smallest file in the torrent to actually download.
  - The script will take care of masquerading you as a seed
- Delete all of the trackers except the one you started a process to masquerade as.
- Edit the tracker left and replace the tracker domain name (and port) with the IP address and port you set the script to listen on.
- Start the torrent!

It'll download the one file (which we need so that your torrent client does periodically announce the status of that torrent), but you'll appear to be seeding it at some variable, realistic rate based on the settings you chose when you started the script.

You can run this for the top 10-20 of the highest-leecher-count torrents on your tracker (to hide in the noise), and choose a sensible upload rate, remember that you're only one of many seeds too.

## References

- http://dandylife.net/docs/BitTorrent-Protocol.pdf
