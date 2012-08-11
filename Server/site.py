import sys, cherrypy, simplejson, jinja2, time
import os.path
import process

from jinja2 import Environment, PackageLoader

env = Environment(loader=jinja2.FileSystemLoader(["/home/robhemsley/webapps/captions/templates/"]))
tutconf = os.path.join(os.path.dirname(__file__), 'config.conf')

processor = process.classifier()

class API_0:
	@cherrypy.expose
	def index(self):
		return ""

	@cherrypy.expose
	def processtxt(self, **kwargs):
		return simplejson.dumps(processor.process(cherrypy.request.remote.ip , kwargs['text']))

class API:
	@cherrypy.expose
	def index(self):
		return "API Version required: v0 etc"
	
class Captions:
	@cherrypy.expose
	def index(self):
		template = env.get_template( "index.html")
		return template.render()
  
if __name__ == '__main__':
	capRoot = Captions()
	capRoot.API = API()
	capRoot.API.v0 = API_0()
	cherrypy.quickstart(capRoot, config=tutconf)

