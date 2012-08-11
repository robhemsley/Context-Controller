import dirtyWords, urllib2, json, simplejson, operator
from calais import Calais

class classifier():
	API_KEY = 'xyby6x47ycxj56bkkb83s9he'

	def __init__(self):
		self.calais = Calais(self.API_KEY, submitter='SocialTV Demo')

	def process(self, ip, text):
		result = self.calais.analyze(text)
		all_tags = []

		if hasattr(result, 'entities'):
			all_tags.extend(result.entities)

		if hasattr(result, 'socialTag'):
	        #all_tags.extend(result.socialTag)
			pass

		if len(all_tags) == 0:
			return []

		output = []
		for tag in all_tags:
			if tag['name'].lower() not in dirtyWords.DIRTY:
				qwiki = self._get_qwiki_url(tag['name'])
				if len(qwiki) > 0:
					img = self._get_google_image(ip, tag['name'])
					print "Tag: "+tag['name']
					output.append({'text':text ,'tag': tag['name'], 'qwiki':qwiki, 'img': img})
		return output

	
	def _get_qwiki_url(self, text):
		try:
			tmp_txt = text.replace(' ', '_')
			response = urllib2.urlopen("http://www.qwiki.com/embed/"+urllib2.quote(tmp_txt)+"?autoplay=true")
			return "http://www.qwiki.com/embed/"+urllib2.quote(tmp_txt)+"?autoplay=true"
	        except urllib2.URLError, e:
			response = urllib2.urlopen("http://embed-api.qwiki.com/api/v1/search.json?count=1&q="+urllib2.quote(text))
			html = response.read()
			html_eval = json.loads(html)
			if len(html_eval) > 0:
				return self._process_qwiki_results(text, html_eval)
			else:
				return []

	def _process_qwiki_results(self, text, results):
		strings = text.split(" ")
		output = {}
		
		for idx, result in enumerate(results):
			output[str(idx)] = 0
			if text == result['title']:
				output[str(idx)] = 10
			for word in strings:
				if (word in result['text'] or word in result['title']):
					output[str(idx)] += 1
		
		sorted_x = sorted(output.iteritems(), key=operator.itemgetter(1))
		tmp = sorted_x[len(sorted_x)-1][0]
		if output['0'] == int(sorted_x[len(sorted_x)-1][1]):
			tmp = '0'
		return results[int(tmp)]['embed_url']+"?autoplay=true"

	def _get_google_image(self, ip, text):
		url = "https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q="+urllib2.quote(text)+"&imgsz=xxlarge&imgtype=photo&userip="+ip
		request = urllib2.Request(url, None)
		response = urllib2.urlopen(request)

		results = simplejson.load(response)
		if results['responseData'] != None:
			return results['responseData']['results'][0]['url']
		else:
			return ""
