#%%
import logging
import requests
import robobrowser
import pandas as pd

from robobrowser import RoboBrowser
from robobrowser.forms.form import Form, Payload, fields, _parse_fields


logger = logging.getLogger(__name__)


class Scrapper(object):
    def __init__(self, skip_objects=None):
        self.skip_objects = skip_objects

    def scrap_process(self, storage):

        # You can iterate over ids, or get list of objects
        # from any API, or iterate throught pages of any site
        # Do not forget to skip already gathered data
        # Here is an example for you
        #     'User-Agent' : 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
        #     'Accept' : 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        #     'Accept-Language' : 'ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4',
        #     'Accept-Encoding' : 'gzip, deflate, sdch'}
        def auth():
            LoginForm=q.get_form(id="aspnetForm")

            LoginForm['ctl00$ctl00$ModalLogin1$LoginTextBox'].value= 'avtostrada'
            LoginForm['ctl00$ctl00$ModalLogin1$PasswordTextBox'].value = '5ed8f5'

            LoginForm.add_field(robobrowser.forms.fields.Input('\<input name="__EVENTARGUMENT" value="" \/\>'))
            LoginForm.add_field(robobrowser.forms.fields.Input('\<input name="__EVENTTARGET" value="ctl00$ctl00$ModalLogin1$ButtonFilter" \/\>'))

            q.submit_form(LoginForm, submit=LoginForm['ctl00$ctl00$ModalLogin1$ButtonFilter'])

           
        def get_download_url(link):
            d=link.get('href')
            return 'http://brokenstone.ru/'+ d
            #content=q.session.get(durl)
        
        def save_download(durl):
            file1=q.session.get(durl)
            #if file1.headers['Content-Type'] == 'application/octet-stream':
            nameFile=(file1.headers['Content-Disposition']).split('=')
            xls_file='./{0}'.format(nameFile[1])
            logger.info(xls_file)
            with open(xls_file, "wb") as output:
                output.write(file1.content)
            return nameFile[1]

            #else:
            #    logger.error(u'Какая то хрень')

        url = storage
        logger.info("Начинаем загрузку")
        q=RoboBrowser()
        q.open(url)
        response = q.state

        if not response.response.ok:
            logger.error(response.response.text)
            # then continue process, or retry, or fix your code
        else:
            auth()
            a = q.get_links('Поставки по жд за')
            durls = list(map(get_download_url, a))
            logger.info(durls)
            #d=a[1].get('href')
            #durl='http://brokenstone.ru/'+ d
            #content=map(q.session.get, durls)

            downloadFales = list(map(save_download, durls))

            logger.info(downloadFales)
            
            dataframe=pd.concat(map(pd.read_excel, downloadFales))

            dataframe.to_pickle('data.pkl')

            logger.info(u'Данные сохранены')
        

                    
            # Note: here json can be used as response.json
            #data = q.response

            # save scrapped objects here
            # you can save url to identify already scrapped objects
            #storage.write_data([url + '\t' + data.replace('\n', '')])
#%%
#Scrapper.scrap_process(Scrapper,'http://brokenstone.ru/supplyfileexport.aspx')