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
import org.xtext.example.rao.rAO.ConstantDeclaration
import org.eclipse.emf.common.util.EList
import org.eclipse.xtext.common.types.JvmMember
import org.eclipse.xtext.common.types.JvmTypeReference
import org.xtext.example.rao.rAO.Entity
import org.eclipse.xtext.xbase.XExpression

class RAOJvmModelInferrer extends AbstractModelInferrer {

	@Inject extension JvmTypesBuilder

	@Inject extension IQualifiedNameProvider

	def dispatch void infer(
		Model element,
		IJvmDeclaredTypeAcceptor acceptor,
		boolean isPreIndexingPhase
	) {
		acceptor.accept(element.toClass(QualifiedName.create("db"))) [
			for (entity : element.objects) {
				switch entity {
					ResourceDeclaration: {
						declVarFull(
							members,
							entity,
							entity.name,
							entity.constructor.inferredType,
							entity.constructor
						)
					}
					ConstantDeclaration: {
						declConstFull(
							members,
							entity,
							entity.constant.variable.name,
							entity.constant.variable.parameterType,
							entity.constant.right
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
							declVarFull(
								members,
								entity,
								param.variable.name,
								param.variable.parameterType,
								param.right
							)
						}
						members += entity.toConstructor [
							for (param : entity.params)
								parameters += entity.toParameter(
									param.variable.name,
									param.variable.parameterType
								)
							body = '''«FOR param : entity.params»
									this.«param.variable.name» = «param.variable.name»;
								«ENDFOR»'''
						]
					]
				}
			}
		}
	}

	def void declVarFull(EList<JvmMember> members, Entity entity, String name, JvmTypeReference type,
		XExpression initExpr) {
		members += entity.toField(name, type)[initializer = initExpr]
		members += entity.toSetter(name, type)
		members += entity.toGetter(name, type)
	}

	def void declConstFull(EList<JvmMember> members, Entity entity, String name, JvmTypeReference type,
		XExpression initExpr) {
		members += entity.toField(name, type) [
			initializer = initExpr
			final = true
		]
		members += entity.toGetter(name, type)
	}
}
