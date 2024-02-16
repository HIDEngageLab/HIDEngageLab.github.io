# Installation

Install Ruby and jekyll bundler:

https://jekyllrb.com/docs/installation/ubuntu/


Attention:

```bash
echo '# Install Ruby Gems to ~/gems' >> ~/.bashrc
echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc
echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```
Install instructions:

https://jekyllrb.com/docs/

# Install, before "bundle install"

```bash
sudo gem install colorator -v 1.1.0
sudo gem install forwardable-extended -v 2.6.0
sudo apt-get install ruby-dev
sudo gem install racc -v 1.6.2
sudo gem install commonmarker -v 0.23.8
sudo gem install http_parser.rb -v 0.8.0
sudo gem install jekyll-watch -v 2.2.1
sudo gem install jekyll-sass-converter -v 1.5.2
```

Permissions:

```bash
sudo chown -R $(whoami) /var/lib/gems/
sudo chown -R $(whoami) /usr/local/bin
```
