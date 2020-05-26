import unittest
import requests

class Backend(unittest.TestCase):
    def test_service(self):
        print ("/")
        r = requests.get('http://172.17.0.1:8080')
        self.assertEqual(r.status_code, 200)

if __name__ == '__main__':
    unittest.main()

   