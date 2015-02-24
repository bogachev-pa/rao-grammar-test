package org.xtext.example.rao.jvmmodel

import com.google.inject.Inject
import org.eclipse.xtext.xbase.jvmmodel.AbstractModelInferrer
import org.eclipse.xtext.xbase.jvmmodel.IJvmDeclaredTypeAcceptor
import org.eclipse.xtext.xbase.jvmmodel.JvmTypesBuilder
import org.eclipse.xtext.naming.IQualifiedNameProvider

import org.xtext.example.rao.rAO.ResourceType
import org.xtext.example.rao.rAO.ResourceDeclaration
import org.eclipse.xtext.naming.QualifiedName
import org.xtext.example.rao.rAO.Model

class RAOJvmModelInferrer extends AbstractModelInferrer {

	@Inject extension JvmTypesBuilder

	@Inject extension IQualifiedNameProvider

	def dispatch void infer(
		Model element, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase
	) {
		acceptor.accept(element.toClass(QualifiedName.create("db"))) [
			for (entity : element.objects) {
				switch entity {
					ResourceDeclaration: {
						members += element.toField(
							entity.name,
							entity.constructor.inferredType
						) [initializer = entity.constructor]
						members += element.toGetter(
							entity.name,
							entity.constructor.inferredType
						)
					}
				}
			}
		]
		for (entity : element.objects) {
			switch entity {
				ResourceType: {
					acceptor.accept(entity.toClass(entity.fullyQualifiedName)) [

						members += entity.toField("name", String.typeRef)

						for (param : entity.params) {
							members += entity.toField(
								param.variable.name,
								param.variable.parameterType
							) [initializer = param.right]
							members += entity.toSetter(
								param.variable.name,
								param.variable.parameterType
							)
							members += entity.toGetter(
								param.variable.name,
								param.variable.parameterType
							)
						}

						members += entity.toConstructor[
							for (param : entity.params)
								parameters += entity.toParameter(
									param.variable.name,
									param.variable.parameterType
								)
							body = '''«FOR param: entity.params»
									this.«param.variable.name» = «param.variable.name»;
								«ENDFOR»'''
						]
					]
				}
			}
		}
	}
}
