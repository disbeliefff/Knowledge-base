
# Flux working schema 


![[Pasted image 20250128110851.png]]


  

# Flux Helm Operator (in the flux stack, responsible for installing, updating and deleting charts)

![[Pasted image 20250128110931.png]]

По факту просто бинарный файл на go, который детектит обновление в файле helm release и на основании этого устанавливает/обновляет/удаляет на основании изменений каких-либо (helm release это просто описание того, какой чарт и откуда устанавливается/изменяется/удаляется)

# Repository Example

![[Pasted image 20250128111010.png]]

  

Resources:

https://www.youtube.com/watch?v=d-H2K4I7-jk

https://www.youtube.com/watch?v=T4fkWIGahiQ&t=1271s

https://fluxcd.io/flux/use-cases/helm/