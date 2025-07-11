from selenium import webdriver
from selenium.webdriver.common.by import By
import time
from bs4 import BeautifulSoup
import threading
from selenium.common.exceptions import NoSuchElementException
import pandas as pd

#%%
driver = webdriver.Chrome()

#%%
# Reading the categories from the file 
categories = [];
with open('./categories.txt', 'r') as file :
       for line in file:
           categories.append(line.strip())

for categorie in categories :
    time.sleep(6)
    driver.get('https://www.roadmap.sh/' + categorie)
    soup = BeautifulSoup(driver.page_source, 'lxml')
    roadmap = soup.select('g > text > tspan')
    with open('roadmaps.txt', 'a') as f:
        for t in roadmap:
            f.write(t.text + " -> ")
        f.write('\n\n')
