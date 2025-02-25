# ddff

## Dependências

requisitos:

* `dvb-apps`
* `ffmpeg`

opcionais:

* `vlc`

## Tabela de frequências

A tabela de frequências descreve os canais da faixa UHF no Brasil.
É documentada pela NBR 15608-1 (tabela 5) e está disponível nesse repositório
no arquivo `freq.conf`.

## Tabela de estações (channels.conf)

A tabela de estações é uma lista com a descrição dos canais sintonizáveis de uma região.
Está disponível nesse repositório sob o nome de `channels.conf` (sintonizado em Brasília em dez-2016).

Se for preciso atualizá-la, utilize o `scan`:

```bash
scan freq.conf > nova_tabela_de_estacoes.conf
```

## Assistindo pelo VLC

O VLC aceita como entrada uma tabela de estações. É uma boa ferramenta para testar 
visualmente a sintonia dos canais. Basta passar o arquivo da tabela como argumento:

```bash
vlc channels.conf
```

## Do DVB para o ffmpeg

### - sintonizando o receptor

Para gerar um stream dvb compatível com o `ffmpeg`, primeiro é preciso adquirir
um `LOCK` (sintonizar o receptor).

Vamos considerar que na tabela de estações exista o canal 'TV SENADO  1' com a seguinte descrição:

```
TV SENADO  1:689142857:INVERSION_AUTO:BANDWIDTH_6_MHZ:FEC_AUTO:FEC_AUTO:QAM_AUTO:TRANSMISSION_MODE_AUTO:GUARD_INTERVAL_AUTO:HIERARCHY_NONE:769:513:16544
```

Para sintonizá-lo, utilize o `tzap` :

```bash 
# o nome do canal é insensível ao caso
$ tzap 'tv senado  1' -r -c channels.conf
status 1f | signal 9341 | snr 00a9 | ber 00000000 | unc 00000000 | FE_HAS_LOCK
status 1f | signal 92e6 | snr 00b1 | ber 00000000 | unc 00000000 | FE_HAS_LOCK
status 1f | signal 92fb | snr 00bc | ber 00000000 | unc 00000000 | FE_HAS_LOCK
status 1f | signal 9324 | snr 009f | ber 00000000 | unc 00000000 | FE_HAS_LOCK
status 1f | signal 9337 | snr 00ba | ber 00000000 | unc 00000000 | FE_HAS_LOCK
# (...)
```

O receptor continuará sintonizado na frequência desejada até que o comando `tzap` seja interrompido.

A saída do comando `tzap` indica a saúde do sinal de TV:

* `status` informa se ocorrem satisfatoriamente a recepção e a decodificação de um stream de vídeo.
O único valor aceitável é `1f`
(veja a [tabela bitmap](https://github.com/torvalds/linux/blob/f9d79126195374c285035777b9d6abd24ceba363/include/uapi/linux/dvb/frontend.h#L252)
para intepretar outros resultados).
* `snr` (_sound/noise ratio_) informa a força do sinal em hexadecimal. Sua escala depende do dispositivo,
variando de 4 a 8 bits (2 a 4 dígitos). Não é necessário que o valor seja alto para uma boa
transmissão, desde que se mantenha estável. Utilize essa coluna como feedback quando for posicionar a antena.
* `unc` (_uncorrected block errors_) reporta a qualidade do sinal. Qualquer valor diferente de 0
significa que haverá chuvisco digital na recepção.

Em algumas versões do tzap, o parâmetro `-r` é obrigatório para a liberação do
dispositivo `/dev/dvb/adapter0/dvr0` para gravação.


### - passando a saída do receptor para o ffmpeg

Uma vez que o _lock_ foi adquirido (`FE_HAS_LOCK`) com uma recepção satisfatória (status == `1f`),
o dispositivo `/dev/dvb/adapter0/dvr0` emitirá um stream no formato `mpegts`.

Para consumir via `ffmpeg`, passe o dispositivo como entrada (`-i`):

```bash
ffmpeg -i /dev/dvb/adapter0/dvr0 saida.mp4 # salva o stream no arquivo saida.mp4 
```

### - read errors

O `ffmpeg` não aceita streams com _read errors_, portanto qualquer erro de transmissão
(como chuviscos e queda de qualidade do sinal) pode travar seu processamento. 

Para passar um stream limpo para o `ffmpeg`, passe-o antes pelo `dd conv=noerror`: 

```bash
dd if=/dev/dvb/adapter0/dvr0 conv=noerror | ffmpeg -i - saida.mp4
# note que o stdin, -, foi utilizado como arquivo de entrada do ffmpeg. 
```

## Transmitindo para um RTMP

Para transmitir para um RTMP, passe a respectiva url como ponto de saída do ffmpeg.

Exemplo:

```bash
dd if=/dev/dvb/adapter0/dvr0 conv=noerror | ffmpeg -i - rtmp://a.rtmp.youtube.com/live2/CHAVE_DO_STREAM
```

É recomendável reencodar o stream de TV em um formato mais adequado para a plataforma
de destino ([Facebook](https://www.facebook.com/facebookmedia/get-started/live), [Youtube](https://support.google.com/youtube/answer/2853702))

O script `ddff.sh` desse repositório apresenta um ajuste ideal para a transmissão em SD para o Facebook.
A chave de acesso deve ser passada como primeiro argumento:

```bash
./ddff.sh "CHAVE_DO_STREAM"
```

## Múltiplos streams

Para enviar o mesmo stream para múltiplos processos simultaneamente, utilize o `pee` do pacote `moreutils`.

```bash
dd if=/dev/dvb/adapter0/dvr0 conv=noerror | ./transcode.sh | pee "./ff.sh 'chave1'" "./ff.sh 'chave2'"
```


## Proxy

O ffmpeg não vai mandar nada por um proxy HTTP. Você vai precisar de algum _proxifier_ para direcionar todo
o fluxo http por um proxy.

No Linux, você pode usar o `proxychains`:

```bash
proxychains ./ddff.sh "CHAVE_DO_STREAM"
``` 

Configure o `proxychains` pelo arquivo `/etc/proxychains.conf`.
Se sua rede proíbe o acesso a DNS externos, comente o parâmetro `proxy_dns`.

## Por onde andei...

* https://wiki.archlinux.org/index.php/DVB-T
* https://www.linuxtv.org/pipermail/linux-dvb/2008-August/028394.html
* https://wiki.gentoo.org/wiki/TV_Tuner#Recording_using_zap_and_cat.7Cdd_.28preferred_method.29
* http://www.tannet.org.uk/using-ffmpeg-to-generate-a-transport-stream-more-details-and-how-to-add-text-overlays/
* http://panteltje.com/panteltje/dvd/
* http://www.waveguide.se/?article=creating-dvb-t-compatible-mpeg2-streams-using-ffmpeg
* https://www.linuxtv.org/wiki/index.php/Testing_your_DVB_device
* https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
* http://linux-dvb.linuxtv.narkive.com/dvrxCE9Q/nova-t-stick-problem
